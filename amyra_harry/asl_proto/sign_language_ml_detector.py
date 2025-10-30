import cv2
import torch
import numpy as np
from PIL import Image
from transformers import AutoImageProcessor, SiglipForImageClassification
import time

class SignLanguageMLDetector:
    def __init__(self, confidence_threshold=0.5):
        """
        Initialize the ML-based sign language detector.

        Args:
            confidence_threshold: Minimum confidence score (0-1) to display a letter
        """
        print("Loading Hugging Face model...")
        self.model_name = "prithivMLmods/Alphabet-Sign-Language-Detection"

        # Load model and processor
        self.model = SiglipForImageClassification.from_pretrained(self.model_name)
        self.processor = AutoImageProcessor.from_pretrained(self.model_name)

        # Set model to evaluation mode
        self.model.eval()

        # Move to GPU if available
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        print(f"Model loaded on {self.device}")

        self.confidence_threshold = confidence_threshold

        # ASL alphabet labels
        self.labels = {
            0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G", 7: "H", 8: "I", 9: "J",
            10: "K", 11: "L", 12: "M", 13: "N", 14: "O", 15: "P", 16: "Q", 17: "R", 18: "S", 19: "T",
            20: "U", 21: "V", 22: "W", 23: "X", 24: "Y", 25: "Z"
        }

    def predict_letter(self, frame):
        """
        Predict the sign language letter from a video frame.

        Args:
            frame: OpenCV frame (BGR format)

        Returns:
            tuple: (predicted_letter, confidence_score)
        """
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Convert to PIL Image
        pil_image = Image.fromarray(rgb_frame)

        # Preprocess image
        inputs = self.processor(images=pil_image, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        # Make prediction
        with torch.no_grad():
            outputs = self.model(**inputs)
            logits = outputs.logits
            probs = torch.nn.functional.softmax(logits, dim=1)

            # Get top prediction
            confidence, predicted_idx = torch.max(probs, dim=1)
            confidence = confidence.item()
            predicted_idx = predicted_idx.item()

        # Only return letter if confidence is above threshold
        if confidence >= self.confidence_threshold:
            letter = self.labels[predicted_idx]
            return letter, confidence
        else:
            return None, confidence

    def draw_letter_or_x(self, frame, letter, confidence):
        """
        Draw detected letter with confidence or red X in top right corner.
        """
        height, width = frame.shape[:2]
        x_pos = width - 120
        y_pos = 60

        if letter:
            # Draw green background box
            cv2.rectangle(frame, (x_pos - 50, y_pos - 55), (x_pos + 50, y_pos + 35), (0, 255, 0), -1)

            # Draw letter in black
            cv2.putText(frame, letter, (x_pos - 25, y_pos + 5),
                       cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 0), 3)

            # Draw confidence score below
            conf_text = f"{confidence:.2f}"
            cv2.putText(frame, conf_text, (x_pos - 35, y_pos + 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
        else:
            # Draw red X
            cv2.line(frame, (x_pos - 30, y_pos - 40), (x_pos + 30, y_pos), (0, 0, 255), 5)
            cv2.line(frame, (x_pos + 30, y_pos - 40), (x_pos - 30, y_pos), (0, 0, 255), 5)

    def draw_info(self, frame, fps):
        """
        Draw information overlay on the frame.
        """
        # Instructions
        cv2.putText(frame, "Show ASL letter to camera", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

        # FPS counter
        cv2.putText(frame, f"FPS: {fps:.1f}", (10, 60),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)

        # Threshold info
        cv2.putText(frame, f"Threshold: {self.confidence_threshold:.2f}", (10, 90),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)

    def run(self, skip_frames=2):
        """
        Main loop to capture video and detect sign language using ML model.

        Args:
            skip_frames: Process every Nth frame to improve performance
        """
        cap = cv2.VideoCapture(0)

        if not cap.isOpened():
            print("Error: Could not open camera")
            return

        # Set camera properties
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_FPS, 30)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

        # Give camera time to initialize
        print("Initializing camera...")
        time.sleep(2)

        # Try reading a few frames to ensure camera is ready
        for _ in range(5):
            ret, frame = cap.read()
            if ret:
                break
            time.sleep(0.5)

        if not ret:
            print("Error: Camera opened but could not read frames")
            print("Try: 1) Check camera permissions, 2) Close other apps using camera")
            cap.release()
            return

        print("ML Sign Language Detector Started")
        print("Press 'q' to quit")
        print("Press 'u' to increase confidence threshold")
        print("Press 'd' to decrease confidence threshold")
        print("\nUsing Hugging Face model for detection")
        print("Supports all 26 ASL letters (A-Z)")

        frame_count = 0
        detected_letter = None
        detected_confidence = 0.0

        # FPS calculation
        fps_start_time = time.time()
        fps_frame_count = 0
        fps = 0.0

        while True:
            ret, frame = cap.read()
            if not ret:
                frame_count += 1
                if frame_count > 30:
                    print("Error: Too many failed frame reads")
                    break
                continue

            frame_count = 0

            # Flip frame horizontally for mirror effect
            frame = cv2.flip(frame, 1)

            # Process every Nth frame for better performance
            if fps_frame_count % skip_frames == 0:
                detected_letter, detected_confidence = self.predict_letter(frame)

            # Draw letter or X in top right corner
            self.draw_letter_or_x(frame, detected_letter, detected_confidence)

            # Calculate FPS
            fps_frame_count += 1
            if fps_frame_count % 10 == 0:
                fps_end_time = time.time()
                fps = 10 / (fps_end_time - fps_start_time)
                fps_start_time = fps_end_time

            # Draw info overlay
            self.draw_info(frame, fps)

            # Show frame
            cv2.imshow('ML Sign Language Detector', frame)

            # Handle key presses
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('u'):
                self.confidence_threshold = min(1.0, self.confidence_threshold + 0.05)
                print(f"Confidence threshold: {self.confidence_threshold:.2f}")
            elif key == ord('d'):
                self.confidence_threshold = max(0.0, self.confidence_threshold - 0.05)
                print(f"Confidence threshold: {self.confidence_threshold:.2f}")

        # Cleanup
        cap.release()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    # Create detector with default confidence threshold of 0.5
    detector = SignLanguageMLDetector(confidence_threshold=0.5)

    # Run the detector (skip_frames=2 means process every 2nd frame for better performance)
    detector.run(skip_frames=2)
