#!/usr/bin/env python3
"""
Generate sample PDFs for testing the PDF search tool.
Creates PDFs with known content to verify search accuracy.
"""

import sys
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch

def create_test_pdf(filename="test_search.pdf"):
    """Create a sample PDF with content about machine learning topics."""
    
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter
    
    # Page 1 - Introduction to Gradient Descent
    y = height - inch
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, y, "Introduction to Gradient Descent")
    
    y -= 0.5 * inch
    c.setFont("Helvetica", 12)
    
    content1 = [
        "Gradient descent is a fundamental optimization algorithm used in machine learning.",
        "The gradient descent method iteratively updates model parameters by moving in the",
        "direction of steepest descent. The learning rate controls the step size and",
        "significantly impacts optimization convergence. For convex functions, gradient",
        "descent guarantees convergence to the global minimum.",
        "",
        "There are several variants of gradient descent. Batch gradient descent uses the",
        "entire dataset to compute gradients. Stochastic gradient descent (SGD) uses single",
        "examples, while mini-batch gradient descent provides a balance between the two.",
        "The choice of variant affects both convergence speed and final accuracy.",
    ]
    
    for line in content1:
        c.drawString(inch, y, line)
        y -= 15
    
    c.showPage()
    
    # Page 2 - Neural Networks
    y = height - inch
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, y, "Neural Networks and Deep Learning")
    
    y -= 0.5 * inch
    c.setFont("Helvetica", 12)
    
    content2 = [
        "Neural networks are computational models inspired by biological neural networks.",
        "Deep learning uses neural networks with multiple layers to learn hierarchical",
        "representations of data. Backpropagation, combined with gradient descent,",
        "enables training of deep neural networks by computing gradients efficiently.",
        "",
        "The architecture of a neural network includes input layers, hidden layers, and",
        "output layers. Activation functions introduce non-linearity, allowing networks",
        "to learn complex patterns. Common activation functions include ReLU, sigmoid,",
        "and tanh. The choice of activation function affects gradient flow during training.",
    ]
    
    for line in content2:
        c.drawString(inch, y, line)
        y -= 15
    
    c.showPage()
    
    # Page 3 - Optimization Techniques
    y = height - inch
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, y, "Advanced Optimization Techniques")
    
    y -= 0.5 * inch
    c.setFont("Helvetica", 12)
    
    content3 = [
        "Modern deep learning relies on sophisticated optimization algorithms beyond basic",
        "gradient descent. Adam optimizer combines momentum and adaptive learning rates,",
        "providing faster convergence for many problems. RMSprop adapts learning rates",
        "based on recent gradient magnitudes, preventing oscillations.",
        "",
        "Momentum-based methods accumulate gradients over time, helping escape local minima",
        "and accelerate convergence. The momentum coefficient determines how much previous",
        "gradients influence current updates. Nesterov momentum provides lookahead by",
        "computing gradients at the anticipated position rather than the current position.",
        "",
        "Learning rate scheduling adjusts the learning rate during training. Common",
        "strategies include step decay, exponential decay, and cosine annealing. Proper",
        "learning rate selection is crucial for optimization success.",
    ]
    
    for line in content3:
        c.drawString(inch, y, line)
        y -= 15
    
    c.showPage()
    
    # Page 4 - Regularization
    y = height - inch
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, y, "Regularization Techniques")
    
    y -= 0.5 * inch
    c.setFont("Helvetica", 12)
    
    content4 = [
        "Regularization prevents overfitting by constraining model complexity. L1 and L2",
        "regularization add penalty terms to the loss function, encouraging smaller weights.",
        "Dropout randomly deactivates neurons during training, forcing the network to learn",
        "robust features that don't rely on specific neurons.",
        "",
        "Batch normalization normalizes layer inputs, reducing internal covariate shift.",
        "This technique stabilizes training and allows higher learning rates. Early stopping",
        "halts training when validation performance stops improving, preventing the model",
        "from overfitting to the training data.",
    ]
    
    for line in content4:
        c.drawString(inch, y, line)
        y -= 15
    
    c.showPage()
    
    # Page 5 - Applications
    y = height - inch
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, y, "Machine Learning Applications")
    
    y -= 0.5 * inch
    c.setFont("Helvetica", 12)
    
    content5 = [
        "Machine learning applications span numerous domains. Computer vision uses",
        "convolutional neural networks for image classification, object detection, and",
        "semantic segmentation. Natural language processing applies transformers and",
        "recurrent networks to tasks like translation, summarization, and question answering.",
        "",
        "Reinforcement learning trains agents through interaction with environments.",
        "The gradient descent optimization framework extends to policy gradients, enabling",
        "learning in complex decision-making scenarios. Applications include robotics,",
        "game playing, and autonomous systems.",
        "",
        "Generative models like GANs and VAEs create new data similar to training examples.",
        "These models use gradient-based optimization to learn complex data distributions,",
        "enabling applications in image synthesis, data augmentation, and creative AI.",
    ]
    
    for line in content5:
        c.drawString(inch, y, line)
        y -= 15
    
    c.save()
    print(f"Created {filename} with 5 pages")
    return filename

def create_large_test_pdf(filename="large_test.pdf", num_pages=100):
    """Create a larger PDF for performance testing."""
    
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter
    
    topics = [
        ("Gradient Descent", "gradient descent optimization algorithm machine learning"),
        ("Neural Networks", "neural networks deep learning backpropagation training"),
        ("Transformers", "transformer attention mechanism self-attention bert gpt"),
        ("Optimization", "adam optimizer momentum learning rate convergence"),
        ("Regularization", "regularization dropout batch normalization overfitting"),
    ]
    
    for page in range(num_pages):
        topic_idx = page % len(topics)
        topic_name, keywords = topics[topic_idx]
        
        y = height - inch
        c.setFont("Helvetica-Bold", 14)
        c.drawString(inch, y, f"Page {page + 1}: {topic_name}")
        
        y -= 0.4 * inch
        c.setFont("Helvetica", 11)
        
        # Generate repetitive but realistic content
        lines = [
            f"This page discusses {topic_name.lower()} in the context of machine learning.",
            f"Key concepts include {keywords}.",
            "",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod",
            "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,",
            "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo",
            "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse",
            "cillum dolore eu fugiat nulla pariatur.",
            "",
            f"The {topic_name.lower()} method is widely used in modern applications.",
            "Practitioners should consider various factors when applying these techniques.",
            "Performance characteristics depend on dataset size and model complexity.",
            "",
            "Additional considerations include computational requirements, memory usage,",
            "and scalability to large-scale problems. Empirical evaluation demonstrates",
            "the effectiveness of these approaches across diverse domains.",
        ]
        
        for line in lines:
            if y < inch:  # Start new page if needed
                break
            c.drawString(inch, y, line)
            y -= 13
        
        c.showPage()
    
    c.save()
    print(f"Created {filename} with {num_pages} pages")
    return filename

def main():
    """Generate test PDFs."""
    if len(sys.argv) > 1:
        if sys.argv[1] == "large":
            num_pages = int(sys.argv[2]) if len(sys.argv) > 2 else 100
            create_large_test_pdf(num_pages=num_pages)
        else:
            create_test_pdf(sys.argv[1])
    else:
        # Create both test files
        create_test_pdf()
        print()
        create_large_test_pdf(num_pages=50)

if __name__ == "__main__":
    main()