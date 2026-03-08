import sys
import json
from datetime import datetime
import uuid
import pathlib
import os
import cv2
import numpy as np
import onnxruntime as ort

translations = {
    "en": {
        "Caries_rec": "Early stage caries detected. Recommend a dental check-up for further assessment and potential filling.",
        "Deep Caries_rec": "Deep Caries detected. Recommend immediate dental consultation for treatment, possibly a filling or root canal.",
        "Impacted_rec": "Impacted tooth detected. Recommend dental consultation for evaluation and potential extraction or orthodontic intervention.",
        "Periapical Lesion_rec": "Periapical lesion detected. Recommend urgent dental consultation for diagnosis and treatment, possibly root canal therapy or extraction.",
        "no_issues_detected": "no issues detected",
        "no_issues_summary": "AI analysis suggests no significant issues. Continue with regular dental check-ups.",
        "issues_detected_summary": "AI analysis detected the following potential issues: {issue_list}. Review of the detailed findings and recommendations is advised for a comprehensive diagnosis.",
        "severity_na": "N/A",
        "quality_good": "good",
        "area_overall": "overall",
        "area_bounding_box": "bounding box [{x1}, {y1}, {x2}, {y2}]",
        "issue_unknown": "Unknown",
        "Caries": "Caries",
        "Deep Caries": "Deep Caries",
        "Impacted": "Impacted",
        "Periapical Lesion": "Periapical Lesion",
    },
    "ar": {
        "Caries_rec": "تم الكشف عن تسوس في مرحلة مبكرة. يوصى بإجراء فحص أسنان لمزيد من التقييم والحشو المحتمل.",
        "Deep Caries_rec": "تم الكشف عن تسوس عميق. يوصى باستشارة طبيب أسنان فورية للعلاج ، ربما حشو أو علاج قناة الجذر.",
        "Impacted_rec": "تم الكشف عن سن منطمر. يوصى باستشارة طبيب أسنان للتقييم والاستخراج المحتمل أو التدخل التقويمي.",
        "Periapical Lesion_rec": "تم الكشف عن آفة حول الذروة. يوصى باستشارة طبيب أسنان عاجلة للتشخيص والعلاج ، وربما علاج قناة الجذر أو الاستخراج.",
        "no_issues_detected": "لم يتم الكشف عن أي مشاكل",
        "no_issues_summary": "يقترح تحليل الذكاء الاصطناعي عدم وجود مشكلات كبيرة. استمر في إجراء فحوصات الأسنان المنتظمة.",
        "issues_detected_summary": "كشف تحليل الذكاء الاصطناعي عن المشكلات المحتملة التالية: {issue_list}. يُنصح بمراجعة النتائج والتوصيات التفصيلية للتشخيص الشامل.",
        "severity_na": "غير متاح",
        "quality_good": "جيد",
        "area_overall": "شامل",
        "area_bounding_box": "مربع الإحاطة [{x1}, {y1}, {x2}, {y2}]",
        "issue_unknown": "غير معروف",
        "Caries": "تسوس",
        "Deep Caries": "تسوس عميق",
        "Impacted": "منطمر",
        "Periapical Lesion": "آفة حول الذروة",
    }
}

class YOLOv8ONNX:
    def __init__(self, model_path):
        import onnxruntime as ort
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at {model_path}")
        self.session = ort.InferenceSession(str(model_path))
        self.input_name = self.session.get_inputs()[0].name
        
        # Extract class names from ONNX metadata if available
        meta = self.session.get_modelmeta().custom_metadata_map
        if 'names' in meta:
            self.class_names = eval(meta['names'])
        else:
            self.class_names = {0: 'Caries', 1: 'Deep Caries', 2: 'Impacted', 3: 'Periapical Lesion'}
            
    def predict(self, image_path, conf_threshold=0.25, iou_threshold=0.45):
        img = cv2.imread(str(image_path))
        if img is None:
            raise FileNotFoundError(f"Could not read image {image_path}")
            
        original_img = img.copy()
        
        # Preprocessing (letterbox)
        shape = img.shape[:2]  # current shape [height, width]
        new_shape = (640, 640)
        r = min(new_shape[0] / shape[0], new_shape[1] / shape[1])
        new_unpad = int(round(shape[1] * r)), int(round(shape[0] * r))
        dw, dh = new_shape[1] - new_unpad[0], new_shape[0] - new_unpad[1]
        dw, dh = dw / 2, dh / 2

        img = cv2.resize(img, new_unpad, interpolation=cv2.INTER_LINEAR)
        top, bottom = int(round(dh - 0.1)), int(round(dh + 0.1))
        left, right = int(round(dw - 0.1)), int(round(dw + 0.1))
        img = cv2.copyMakeBorder(img, top, bottom, left, right, cv2.BORDER_CONSTANT, value=(114, 114, 114))

        # Convert HWC to CHW, BGR to RGB
        x = img.transpose((2, 0, 1))[::-1]
        x = np.ascontiguousarray(x, dtype=np.float32) / 255.0
        x = np.expand_dims(x, axis=0) # shape (1, 3, 640, 640)
        
        # Inference
        outputs = self.session.run(None, {self.input_name: x})
        
        # Postprocessing
        predictions = np.squeeze(outputs[0]).T  # shape: (8400, 4 + classes)
        
        scores = np.max(predictions[:, 4:], axis=1)
        predictions = predictions[scores > conf_threshold]
        scores = scores[scores > conf_threshold]
        
        if len(scores) == 0:
            return [], original_img
            
        class_ids = np.argmax(predictions[:, 4:], axis=1)
        boxes = predictions[:, :4]
        
        # xywh to x1 y1 w h for NMS
        boxes_xywh = np.copy(boxes)
        boxes_xywh[:, 0] = boxes[:, 0] - boxes[:, 2] / 2
        boxes_xywh[:, 1] = boxes[:, 1] - boxes[:, 3] / 2
        
        indices = cv2.dnn.NMSBoxes(boxes_xywh.tolist(), scores.tolist(), conf_threshold, iou_threshold)
        
        results = []
        if len(indices) > 0:
            for i in indices.flatten():
                box = boxes[i]
                x1 = box[0] - box[2] / 2
                y1 = box[1] - box[3] / 2
                x2 = box[0] + box[2] / 2
                y2 = box[1] + box[3] / 2
                
                # Rescale boxes back to original image dimensions
                x1 = (x1 - left) / r
                y1 = (y1 - top) / r
                x2 = (x2 - left) / r
                y2 = (y2 - top) / r
                
                # Clamp to image boundaries
                x1 = max(0, min(shape[1], x1))
                y1 = max(0, min(shape[0], y1))
                x2 = max(0, min(shape[1], x2))
                y2 = max(0, min(shape[0], y2))
                
                results.append({
                    "box": [round(float(x1)), round(float(y1)), round(float(x2)), round(float(y2))],
                    "confidence": float(scores[i]),
                    "class_id": int(class_ids[i]),
                    "class_name": self.class_names.get(int(class_ids[i]), "Unknown")
                })
                
        return results, original_img

    def draw_boxes(self, img, results):
        for r in results:
            x1, y1, x2, y2 = r["box"]
            cls_name = r["class_name"]
            conf = r["confidence"]
            
            cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
            label = f"{cls_name} {conf:.2f}"
            cv2.putText(img, label, (x1, max(y1 - 10, 10)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        return img


def analyze_xray(image_path, patient_name, locale='en'):
    try:
        t = translations.get(locale, translations['en'])

        # --- 1. Setup paths ---
        image_path = pathlib.Path(image_path)
        script_dir = pathlib.Path(__file__).parent.resolve()
        model_path = script_dir / "best.onnx"
        
        output_dir = script_dir / "annotated_images"
        os.makedirs(output_dir, exist_ok=True)
        
        # --- 2. Load Model ---
        model = YOLOv8ONNX(model_path)

        # --- 3. Run Prediction ---
        results, original_img = model.predict(image_path)
        
        # --- 4. Process Results and Save Image ---
        annotated_img = model.draw_boxes(original_img.copy(), results)
        
        # Create a safe filename from the patient name
        safe_patient_name = "".join(c for c in patient_name if c.isalnum() or c in (' ', '_')).rstrip()
        safe_patient_name = safe_patient_name.replace(' ', '_')
        file_name = f"{safe_patient_name}_{image_path.stem}.jpg"
        
        annotated_image_path = output_dir / file_name
        
        # Save the image
        cv2.imwrite(str(annotated_image_path), annotated_img)

        # --- 5. Format Findings ---
        findings = []

        for r in results:
            issue_key = r["class_name"]
            issue = t.get(issue_key, issue_key)
            confidence = round(r["confidence"], 2)
            
            x1, y1, x2, y2 = r["box"]
            area_description = t["area_bounding_box"].format(x1=x1, y1=y1, x2=x2, y2=y2)

            findings.append({
                "area": area_description,
                "issue": issue,
                "confidence": confidence,
                "severity": t["severity_na"], 
                "recommendation": t.get(f"{issue_key}_rec", f"Professional consultation recommended for detected {issue}.")
            })

        if not findings:
            findings.append({
                "area": t["area_overall"],
                "issue": t["no_issues_detected"],
                "confidence": 1.0,
                "severity": "none",
                "recommendation": t["no_issues_summary"]
            })
            medical_advice_summary = t["no_issues_summary"]
        else:
            issue_list = ", ".join(set(f["issue"] for f in findings))
            medical_advice_summary = t["issues_detected_summary"].format(issue_list=issue_list)

        output = {
            "analysis_id": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "image_path": str(image_path),
            "annotated_image_path": str(annotated_image_path),
            "analysis_status": "completed",
            "image_quality": t["quality_good"],
            "findings": findings,
            "medical_advice_summary": medical_advice_summary
        }
        return output

    except FileNotFoundError as e:
        return {"analysis_status": "error", "message": str(e)}
    except Exception as e:
        import traceback
        return {"analysis_status": "error", "message": f"An unexpected error occurred: {e}\n{traceback.format_exc()}"}

if __name__ == "__main__":
    if len(sys.argv) > 3:
        image_file_path = sys.argv[1]
        patient_name = sys.argv[2]
        locale = sys.argv[3]
        analysis_output = analyze_xray(image_file_path, patient_name, locale)
        print(json.dumps(analysis_output, indent=4))
    elif len(sys.argv) > 2:
        image_file_path = sys.argv[1]
        patient_name = sys.argv[2]
        analysis_output = analyze_xray(image_file_path, patient_name)
        print(json.dumps(analysis_output, indent=4))
    else:
        error_message = {
            "analysis_status": "error", 
            "message": "No image path or patient name provided. Usage: python xray_analyzer.py <image_path> <patient_name> [locale]"
        }
        print(json.dumps(error_message, indent=4))
        sys.exit(1)
