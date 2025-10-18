import cv2
import mediapipe as mp
import numpy as np
import time

class SignLanguageDetector:
    def __init__(self):
        # Initialize MediaPipe Hands
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        self.mp_draw = mp.solutions.drawing_utils

    def get_finger_states(self, landmarks):
        """
        Determine which fingers are extended.
        Returns: [thumb, index, middle, ring, pinky] (True if extended)
        """
        finger_tips = [4, 8, 12, 16, 20]  # Tip landmarks
        finger_pips = [3, 6, 10, 14, 18]  # PIP joint landmarks

        fingers_extended = []

        # Thumb (check x-coordinate instead of y)
        if landmarks[finger_tips[0]].x < landmarks[finger_pips[0]].x:
            fingers_extended.append(True)
        else:
            fingers_extended.append(False)

        # Other fingers (check y-coordinate)
        for i in range(1, 5):
            if landmarks[finger_tips[i]].y < landmarks[finger_pips[i]].y:
                fingers_extended.append(True)
            else:
                fingers_extended.append(False)

        return fingers_extended

    def recognize_letter(self, landmarks):
        """
        Recognize basic ASL letters based on hand landmarks.
        This is a simplified version - real ASL recognition requires ML models.
        """
        fingers = self.get_finger_states(landmarks)
        thumb, index, middle, ring, pinky = fingers

        # Calculate distances and positions for more complex gestures
        thumb_tip = landmarks[4]
        thumb_ip = landmarks[3]
        index_tip = landmarks[8]
        index_pip = landmarks[6]
        middle_tip = landmarks[12]
        middle_pip = landmarks[10]
        ring_tip = landmarks[16]
        ring_pip = landmarks[14]
        pinky_tip = landmarks[20]
        pinky_pip = landmarks[18]
        wrist = landmarks[0]

        # Distance between thumb and index finger tips
        thumb_index_dist = np.sqrt(
            (thumb_tip.x - index_tip.x)**2 +
            (thumb_tip.y - index_tip.y)**2
        )

        # Distance between thumb and middle finger
        thumb_middle_dist = np.sqrt(
            (thumb_tip.x - middle_tip.x)**2 +
            (thumb_tip.y - middle_tip.y)**2
        )

        # Check if fingers are close together (for U)
        index_middle_dist = np.sqrt(
            (index_tip.x - middle_tip.x)**2 +
            (index_tip.y - middle_tip.y)**2
        )

        # Count extended fingers
        num_extended = sum(fingers)

        # Basic letter recognition rules (ordered by distinctiveness)

        # A: Closed fist with thumb on side (only thumb extended)
        if thumb and not index and not middle and not ring and not pinky:
            if thumb_tip.y > thumb_ip.y:  # Thumb pointing up/side
                return 'A'

        # B: All fingers extended straight up, thumb tucked
        if not thumb and index and middle and ring and pinky:
            return 'B'

        # C: Curved hand (thumb extended, others curved)
        if thumb and not index and not middle and not ring and not pinky:
            if thumb_tip.y < thumb_ip.y:  # Thumb curved
                return 'C'

        # D: Index finger up, thumb touches middle/ring, other fingers down
        if not thumb and index and not middle and not ring and not pinky:
            if thumb_middle_dist < 0.1:
                return 'D'

        # E: All fingers curled down with thumb across
        if not any(fingers):
            return 'E'

        # F: Index and thumb form circle, other three fingers up
        if thumb_index_dist < 0.08 and middle and ring and pinky:
            return 'F'

        # G: Index and thumb pointing horizontally (like pointing)
        if thumb and index and not middle and not ring and not pinky:
            if abs(index_tip.y - thumb_tip.y) < 0.1:  # Both at same height
                return 'G'

        # H: Index and middle extended sideways (horizontally)
        if not thumb and index and middle and not ring and not pinky:
            if index_middle_dist < 0.05:  # Fingers together
                return 'H'

        # I: Only pinky extended
        if not thumb and not index and not middle and not ring and pinky:
            return 'I'

        # K: Index and middle up in V, thumb touches middle
        if not thumb and index and middle and not ring and not pinky:
            if thumb_middle_dist < 0.1 and index_middle_dist > 0.1:
                return 'K'

        # L: Thumb and index extended, forming L shape (90 degrees)
        if thumb and index and not middle and not ring and not pinky:
            if abs(thumb_tip.x - index_tip.x) > 0.15:  # Wide apart
                return 'L'

        # M: Thumb under first three fingers (fist-like)
        if not thumb and not index and not middle and not ring and not pinky:
            if thumb_tip.y < landmarks[9].y:  # Thumb tucked under
                return 'M'

        # N: Thumb under first two fingers (similar to M but less fingers)
        if not thumb and not index and not middle and not ring and not pinky:
            if thumb_tip.y < landmarks[7].y and thumb_tip.y > landmarks[11].y:
                return 'N'

        # O: All fingers curved forming circle
        if thumb_index_dist < 0.12 and not index and not middle and not ring and not pinky:
            return 'O'

        # P: Index pointing down, middle horizontal
        if not thumb and index and middle and not ring and not pinky:
            if index_tip.y > index_pip.y:  # Index pointing down
                return 'P'

        # Q: Index and thumb pointing down
        if thumb and index and not middle and not ring and not pinky:
            if thumb_tip.y > landmarks[2].y and index_tip.y > index_pip.y:
                return 'Q'

        # R: Index and middle crossed
        if not thumb and index and middle and not ring and not pinky:
            if thumb_middle_dist > 0.1 and index_middle_dist < 0.04:
                return 'R'

        # S: Fist with thumb across fingers
        if not index and not middle and not ring and not pinky:
            if thumb_tip.x > wrist.x:  # Thumb visible on side
                return 'S'

        # T: Thumb between index and middle
        if not thumb and not index and not middle and not ring and not pinky:
            if landmarks[2].y < landmarks[5].y:  # Thumb tip between fingers
                return 'T'

        # U: Index and middle together, extended up
        if not thumb and index and middle and not ring and not pinky:
            if index_middle_dist < 0.05:  # Very close together
                return 'U'

        # V: Index and middle extended in V shape (peace sign)
        if not thumb and index and middle and not ring and not pinky:
            if index_middle_dist > 0.08:  # Fingers apart
                return 'V'

        # W: Index, middle, and ring extended
        if not thumb and index and middle and ring and not pinky:
            return 'W'

        # X: Index finger bent/hooked
        if not thumb and not index and not middle and not ring and not pinky:
            if index_tip.y < index_pip.y and index_tip.y > landmarks[7].y:
                return 'X'

        # Y: Thumb and pinky extended (hang loose)
        if thumb and not index and not middle and not ring and pinky:
            return 'Y'

        # Z: Index finger extended (motion-based, hard to detect statically)
        if not thumb and index and not middle and not ring and not pinky:
            return 'Z'

        return None

    def draw_letter_or_x(self, frame, letter):
        """
        Draw detected letter or red X in top right corner.
        """
        height, width = frame.shape[:2]
        x_pos = width - 100
        y_pos = 60

        if letter:
            # Draw green background box
            cv2.rectangle(frame, (x_pos - 40, y_pos - 50), (x_pos + 40, y_pos + 10), (0, 255, 0), -1)
            # Draw letter in black
            cv2.putText(frame, letter, (x_pos - 20, y_pos),
                       cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 0), 3)
        else:
            # Draw red X
            cv2.line(frame, (x_pos - 30, y_pos - 40), (x_pos + 30, y_pos), (0, 0, 255), 5)
            cv2.line(frame, (x_pos + 30, y_pos - 40), (x_pos - 30, y_pos), (0, 0, 255), 5)

    def run(self):
        """
        Main loop to capture video and detect sign language.
        """
        cap = cv2.VideoCapture(0)

        if not cap.isOpened():
            print("Error: Could not open camera")
            return

        # Set camera properties for better compatibility
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

        print("Sign Language Detector Started")
        print("Press 'q' to quit")
        print("\nSupported letters: A-Z (all 26 ASL letters)")
        print("Note: Some letters may require precise hand positioning")

        frame_count = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                # Skip occasional failed reads instead of exiting
                frame_count += 1
                if frame_count > 30:
                    print("Error: Too many failed frame reads")
                    break
                continue

            frame_count = 0  # Reset counter on successful read

            # Flip frame horizontally for mirror effect
            frame = cv2.flip(frame, 1)

            # Convert to RGB for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Process frame with MediaPipe
            results = self.hands.process(rgb_frame)

            detected_letter = None

            # If hand landmarks are detected
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Draw hand landmarks on frame
                    self.mp_draw.draw_landmarks(
                        frame,
                        hand_landmarks,
                        self.mp_hands.HAND_CONNECTIONS
                    )

                    # Recognize letter
                    detected_letter = self.recognize_letter(hand_landmarks.landmark)

            # Draw letter or X in top right corner
            self.draw_letter_or_x(frame, detected_letter)

            # Display instructions
            cv2.putText(frame, "Show ASL letter to camera", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

            # Show frame
            cv2.imshow('Sign Language Detector', frame)

            # Exit on 'q' press
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        # Cleanup
        cap.release()
        cv2.destroyAllWindows()
        self.hands.close()


if __name__ == "__main__":
    detector = SignLanguageDetector()
    detector.run()
