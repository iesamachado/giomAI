document.addEventListener('DOMContentLoaded', () => {
    const navbar = document.querySelector('.navbar');
    const cards = document.querySelectorAll('.card');

    // Efecto de scroll en la barra de navegación
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.style.background = 'rgba(9, 9, 14, 0.95)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.5)';
        } else {
            navbar.style.background = 'rgba(9, 9, 14, 0.8)';
            navbar.style.boxShadow = 'none';
        }
    });

    // Animación de aparición (fade-in up) para las tarjetas de arquitectura
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
                observer.unobserve(entry.target); // Solo animar la primera vez
            }
        });
    }, observerOptions);

    cards.forEach((card, index) => {
        // Estado inicial de la tarjeta
        card.style.opacity = '0';
        card.style.transform = 'translateY(40px)';
        // Añadir retraso escalonado basado en el índice
        card.style.transition = `opacity 0.6s ease ${index * 0.15}s, transform 0.6s ease ${index * 0.15}s, border-color 0.3s ease, background 0.3s ease`;
        observer.observe(card);
    });
});
