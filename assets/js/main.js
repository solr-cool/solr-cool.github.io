  // Smooth-scroll for in-page anchors
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      const id = a.getAttribute('href');
      if (id.length < 2) return;
      const el = document.querySelector(id);
      if (!el) return;
      e.preventDefault();
      window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY - 80, behavior: 'smooth' });
    });
  });

  // Active TOC highlight
  const tocLinks = [...document.querySelectorAll('.toc a')];
  const sectionMap = tocLinks.map(a => {
    const id = a.getAttribute('href').slice(1);
    return { a, el: document.getElementById(id) };
  }).filter(x => x.el);

  const onScroll = () => {
    const y = window.scrollY + 120;
    let current = sectionMap[0];
    for (const s of sectionMap) {
      if (s.el.offsetTop <= y) current = s;
    }
    sectionMap.forEach(s => {
      if (s === current) s.a.style.color = 'var(--red)';
      else s.a.style.color = '';
    });
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
