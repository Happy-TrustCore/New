-- CodePath Academy — initial course content
-- Run this after db/schema.sql. This is the real (if early) curriculum, fully
-- bilingual (English + German): Foundation (2 lessons), the first 16 free
-- Frontend lessons, and the first 8 free Backend lessons — enough to take a
-- student from zero through a complete HTML/CSS site and a working mental
-- model of how servers work. More lessons can be added later through the
-- admin panel at /admin. This file is generated — see the project's dev
-- history for the generator script if you need to regenerate it.

insert into courses (slug, title, description, sort_order) values
  ('foundation', '{"en":"Foundation","de":"Foundation"}'::jsonb, '{"en":"Understand how code and the web work.","de":"Verstehe, wie Code und das Web funktionieren."}'::jsonb, 1),
  ('frontend', '{"en":"Frontend Development","de":"Frontend-Entwicklung"}'::jsonb, '{"en":"HTML, CSS, JavaScript and React — one growing project.","de":"HTML, CSS, JavaScript und React — ein wachsendes Projekt."}'::jsonb, 2),
  ('backend', '{"en":"Backend Development","de":"Backend-Entwicklung"}'::jsonb, '{"en":"Servers, Node.js, databases and authentication.","de":"Server, Node.js, Datenbanken und Authentifizierung."}'::jsonb, 3)
on conflict (slug) do nothing;

-- ── Foundation ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'foundation'),
    'how-programming-works',
    '{"en":"How Programming Works","de":"Wie Programmieren funktioniert"}'::jsonb,
    '[{"step":1,"text":{"en":"A computer only follows exact instructions. Programming is the act of writing those instructions in a language it understands.","de":"Ein Computer folgt nur exakten Anweisungen. Programmieren bedeutet, diese Anweisungen in einer Sprache zu schreiben, die er versteht."}},{"step":2,"text":{"en":"Every app you use — a website, a game, a banking app — is just instructions, run one after another.","de":"Jede App, die du nutzt — eine Website, ein Spiel, eine Banking-App — besteht nur aus Anweisungen, die nacheinander ausgeführt werden."}},{"step":3,"text":{"en":"In this course you will write real instructions yourself, starting with the language browsers understand: HTML.","de":"In diesem Kurs schreibst du selbst echte Anweisungen — angefangen mit der Sprache, die Browser verstehen: HTML."}}]'::jsonb,
    null,
    'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'foundation'),
    'how-websites-work',
    '{"en":"How Websites Work","de":"Wie Websites funktionieren"}'::jsonb,
    '[{"step":1,"text":{"en":"When you open a website, your browser sends a request out to a server somewhere else in the world.","de":"Wenn du eine Website öffnest, sendet dein Browser eine Anfrage an einen Server irgendwo auf der Welt."}},{"step":2,"text":{"en":"The server sends back files — HTML, CSS, JavaScript — and your browser turns them into the page you see.","de":"Der Server sendet Dateien zurück — HTML, CSS, JavaScript — und dein Browser macht daraus die Seite, die du siehst."}},{"step":3,"text":{"en":"Frontend is everything the browser shows you. Backend is everything happening on that server. You will build both.","de":"Frontend ist alles, was dir der Browser zeigt. Backend ist alles, was auf diesem Server passiert. Du wirst beides bauen."}}]'::jsonb,
    null,
    'beginner', true, 2
  )
on conflict (slug) do nothing;

-- ── Frontend: 16 free lessons ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'frontend'),
    'html-hello-world',
    '{"en":"HTML: Your First Website","de":"HTML: Deine erste Website"}'::jsonb,
    '[{"step":1,"text":{"en":"HTML creates the structure and content of a website. There is no design yet — just content.","de":"HTML erstellt die Struktur und den Inhalt einer Website. Design gibt es noch nicht — nur Inhalt."}},{"step":2,"text":{"en":"<h1> creates a big heading. <p> creates a paragraph of text.","de":"<h1> erzeugt eine große Überschrift. <p> erzeugt einen Textabsatz."}},{"step":3,"text":{"en":"Try changing the name in the heading below, then press Run to see your website update.","de":"Ändere den Namen in der Überschrift unten und klicke auf Ausführen, um deine Website zu aktualisieren."}}]'::jsonb,
    '{"html":"<h1>Hello, my name is Ahmed</h1>\n<h2>I am learning coding</h2>\n<p>This is my first website.</p>"}'::jsonb,
    'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-styling-basics',
    '{"en":"CSS: Styling Your Website","de":"CSS: Deine Website gestalten"}'::jsonb,
    '[{"step":1,"text":{"en":"CSS starts here — but your HTML does not restart. You are improving the same website from the last lesson.","de":"CSS beginnt hier — aber dein HTML startet nicht neu. Du verbesserst dieselbe Website aus der letzten Lektion."}},{"step":2,"text":{"en":"HTML creates the elements. CSS changes how they look: color, size, spacing.","de":"HTML erstellt die Elemente. CSS verändert, wie sie aussehen: Farbe, Größe, Abstand."}},{"step":3,"text":{"en":"Try changing the color or font-size values below, then press Run.","de":"Ändere die Werte für color oder font-size unten und klicke auf Ausführen."}}]'::jsonb,
    '{"html":"<h1>Hello, my name is Ahmed</h1>\n<p>This is my first website.</p>","css":"h1 {\n  color: #34d399;\n}\n\np {\n  font-size: 20px;\n}"}'::jsonb,
    'beginner', true, 2
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-css-div-profile-card',
    '{"en":"Building a Profile Card","de":"Eine Profilkarte bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"New HTML: <div> groups content together, and <img> shows a picture. Think of a <div> as a box you can style.","de":"Neu in HTML: <div> gruppiert Inhalte, und <img> zeigt ein Bild. Stell dir ein <div> als Box vor, die du gestalten kannst."}},{"step":2,"text":{"en":"New CSS: background-color fills a box with color. border adds an outline. padding adds space inside the box.","de":"Neu in CSS: background-color füllt eine Box mit Farbe. border fügt einen Rahmen hinzu. padding fügt Abstand innerhalb der Box hinzu."}},{"step":3,"text":{"en":"Turn your name and role into a profile card: a box with a background, some padding, and rounded corners.","de":"Verwandle deinen Namen und deine Rolle in eine Profilkarte: eine Box mit Hintergrund, etwas Innenabstand und abgerundeten Ecken."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <img src=\"https://placehold.co/80\" alt=\"Profile photo\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":".card {\n  background-color: #111827;\n  color: white;\n  border: 1px solid #333;\n  border-radius: 12px;\n  padding: 20px;\n  width: 220px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, 3
  ),
  (
    (select id from courses where slug = 'frontend'),
    'website-structure-nav-footer',
    '{"en":"Real Website Structure: Header, Nav, Footer","de":"Echte Website-Struktur: Header, Nav, Footer"}'::jsonb,
    '[{"step":1,"text":{"en":"New HTML: <nav> holds your navigation links. <footer> holds content at the bottom of the page, like copyright text.","de":"Neu in HTML: <nav> enthält deine Navigationslinks. <footer> enthält Inhalte am unteren Seitenrand, wie Copyright-Text."}},{"step":2,"text":{"en":"New CSS: display: flex arranges elements in a row instead of stacking them.","de":"Neu in CSS: display: flex ordnet Elemente in einer Reihe an, statt sie zu stapeln."}},{"step":3,"text":{"en":"Add a navigation bar with links, and a footer, to the profile card page you started.","de":"Füge der Profilkarten-Seite, die du begonnen hast, eine Navigationsleiste mit Links und einen Footer hinzu."}}]'::jsonb,
    '{"html":"<header>\n  <nav>\n    <a href=\"#\">Home</a>\n    <a href=\"#\">About</a>\n    <a href=\"#\">Contact</a>\n  </nav>\n</header>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":"nav {\n  display: flex;\n  gap: 16px;\n}\n\nnav a {\n  color: #34d399;\n  text-decoration: none;\n}\n\nfooter {\n  margin-top: 40px;\n  color: #888;\n  font-size: 14px;\n}"}'::jsonb,
    'beginner', true, 4
  ),
  (
    (select id from courses where slug = 'frontend'),
    'flexbox-layout-basics',
    '{"en":"Flexbox: Arranging Elements","de":"Flexbox: Elemente anordnen"}'::jsonb,
    '[{"step":1,"text":{"en":"Flexbox controls how elements line up. justify-content controls horizontal spacing. align-items controls vertical alignment.","de":"Flexbox steuert, wie Elemente ausgerichtet werden. justify-content steuert den horizontalen Abstand. align-items steuert die vertikale Ausrichtung."}},{"step":2,"text":{"en":"gap adds space between flex items without needing margin on each one.","de":"gap fügt Abstand zwischen Flex-Elementen hinzu, ohne dass du für jedes einzeln margin brauchst."}},{"step":3,"text":{"en":"Arrange your nav links with space between them, and center your profile card on the page.","de":"Ordne deine Nav-Links mit Abstand zueinander an und zentriere deine Profilkarte auf der Seite."}}]'::jsonb,
    '{"html":"<nav>\n  <a href=\"#\">Home</a>\n  <a href=\"#\">About</a>\n  <a href=\"#\">Contact</a>\n</nav>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":"nav {\n  display: flex;\n  justify-content: space-between;\n  gap: 16px;\n}\n\nbody {\n  display: flex;\n  flex-direction: column;\n  align-items: center;\n}"}'::jsonb,
    'beginner', true, 5
  ),
  (
    (select id from courses where slug = 'frontend'),
    'semantic-html-sections',
    '{"en":"Semantic HTML: main, section, article","de":"Semantisches HTML: main, section, article"}'::jsonb,
    '[{"step":1,"text":{"en":"<main> marks the primary content of the page. <section> groups a themed chunk of content. <article> is a self-contained piece of content.","de":"<main> markiert den Hauptinhalt der Seite. <section> gruppiert einen thematischen Inhaltsabschnitt. <article> ist ein eigenständiger Inhaltsblock."}},{"step":2,"text":{"en":"Using the right tag (instead of always <div>) helps browsers, search engines, and screen readers understand your page.","de":"Das richtige Tag zu verwenden (statt immer <div>) hilft Browsern, Suchmaschinen und Screenreadern, deine Seite zu verstehen."}},{"step":3,"text":{"en":"Wrap your profile card in a <main>, and add a new <section> introducing your skills.","de":"Umschließe deine Profilkarte mit einem <main> und füge eine neue <section> hinzu, die deine Fähigkeiten vorstellt."}}]'::jsonb,
    '{"html":"<main>\n  <div class=\"card\">\n    <h2>Ahmed</h2>\n    <p>Developer</p>\n  </div>\n\n  <section>\n    <h3>Skills</h3>\n    <p>HTML, CSS, JavaScript</p>\n  </section>\n</main>","css":"section {\n  margin-top: 24px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, 6
  ),
  (
    (select id from courses where slug = 'frontend'),
    'typography-basics',
    '{"en":"Typography: Fonts That Feel Professional","de":"Typografie: Schriften, die professionell wirken"}'::jsonb,
    '[{"step":1,"text":{"en":"font-family sets the typeface. font-weight controls boldness. line-height controls space between lines of text.","de":"font-family legt die Schriftart fest. font-weight steuert die Fettung. line-height steuert den Zeilenabstand."}},{"step":2,"text":{"en":"Good typography is one of the fastest ways to make a website look professional.","de":"Gute Typografie ist einer der schnellsten Wege, eine Website professionell wirken zu lassen."}},{"step":3,"text":{"en":"Update your page fonts: a bold heading, and a comfortable line-height for paragraphs.","de":"Aktualisiere die Schriften deiner Seite: eine fette Überschrift und einen angenehmen Zeilenabstand für Absätze."}}]'::jsonb,
    '{"html":"<h2>Ahmed</h2>\n<p>I build websites that work well and look great. Learning to code, one project at a time.</p>","css":"h2 {\n  font-family: Georgia, serif;\n  font-weight: 700;\n}\n\np {\n  font-family: Arial, sans-serif;\n  line-height: 1.6;\n}"}'::jsonb,
    'beginner', true, 7
  ),
  (
    (select id from courses where slug = 'frontend'),
    'box-model-deep-dive',
    '{"en":"The Box Model: Margin vs Padding","de":"Das Box-Modell: Margin vs. Padding"}'::jsonb,
    '[{"step":1,"text":{"en":"Every HTML element is a box. padding is space INSIDE the border. margin is space OUTSIDE the border, between elements.","de":"Jedes HTML-Element ist eine Box. padding ist der Abstand INNERHALB des Rahmens. margin ist der Abstand AUSSERHALB des Rahmens, zwischen Elementen."}},{"step":2,"text":{"en":"box-sizing: border-box makes width and height include padding and border, which avoids surprises.","de":"box-sizing: border-box sorgt dafür, dass width und height padding und border mit einschließen — das verhindert Überraschungen."}},{"step":3,"text":{"en":"Adjust the spacing on this card using margin and padding correctly.","de":"Passe den Abstand dieser Karte mit margin und padding richtig an."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":"* {\n  box-sizing: border-box;\n}\n\n.card {\n  margin: 20px;\n  padding: 20px;\n  border: 1px solid #333;\n  width: 240px;\n}"}'::jsonb,
    'beginner', true, 8
  ),
  (
    (select id from courses where slug = 'frontend'),
    'hero-section',
    '{"en":"Building a Hero Section","de":"Eine Hero-Section bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"A hero section is the big, eye-catching area at the top of a landing page: a large heading, short text, and a button.","de":"Eine Hero-Section ist der große, auffällige Bereich oben auf einer Landingpage: eine große Überschrift, kurzer Text und ein Button."}},{"step":2,"text":{"en":"A large font-size on the heading and a call-to-action button draw the visitor''s attention immediately.","de":"Eine große font-size bei der Überschrift und ein Call-to-Action-Button ziehen die Aufmerksamkeit der Besucher sofort auf sich."}},{"step":3,"text":{"en":"Build a hero section for your own site: your name, a one-line pitch, and a button.","de":"Baue eine Hero-Section für deine eigene Seite: deinen Namen, einen kurzen Pitch und einen Button."}}]'::jsonb,
    '{"html":"<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n  <button>Contact Me</button>\n</section>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\n.hero h1 {\n  font-size: 48px;\n}\n\n.hero button {\n  margin-top: 16px;\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  font-weight: 600;\n  cursor: pointer;\n}"}'::jsonb,
    'beginner', true, 9
  ),
  (
    (select id from courses where slug = 'frontend'),
    'landing-page-assembly',
    '{"en":"Assembling a Landing Page","de":"Eine Landingpage zusammensetzen"}'::jsonb,
    '[{"step":1,"text":{"en":"A landing page combines everything so far: header + nav, a hero section, a features/about section, and a footer.","de":"Eine Landingpage kombiniert alles bisher Gelernte: Header + Nav, eine Hero-Section, eine Features-/Über-mich-Section und einen Footer."}},{"step":2,"text":{"en":"This is where your project stops being ''a page with stuff on it'' and starts being a real website.","de":"Ab hier hört dein Projekt auf, „eine Seite mit irgendwas drauf“ zu sein, und wird zu einer echten Website."}},{"step":3,"text":{"en":"Combine your hero, an about section, and a footer into one flowing page.","de":"Kombiniere deine Hero-Section, eine Über-mich-Section und einen Footer zu einer durchgängigen Seite."}}]'::jsonb,
    '{"html":"<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>About Me</h2>\n  <p>I''m learning to code with CodePath Academy.</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}"}'::jsonb,
    'beginner', true, 10
  ),
  (
    (select id from courses where slug = 'frontend'),
    'responsive-images',
    '{"en":"Responsive Images","de":"Responsive Bilder"}'::jsonb,
    '[{"step":1,"text":{"en":"max-width: 100% stops an image from overflowing its container on small screens.","de":"max-width: 100% verhindert, dass ein Bild auf kleinen Bildschirmen über seinen Container hinausragt."}},{"step":2,"text":{"en":"object-fit: cover crops an image neatly to fill a fixed-size box without stretching it.","de":"object-fit: cover schneidet ein Bild sauber zu, damit es eine Box mit fester Größe füllt, ohne es zu verzerren."}},{"step":3,"text":{"en":"Make the image in your card responsive.","de":"Mache das Bild in deiner Karte responsive."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <img src=\"https://placehold.co/400x200\" alt=\"Cover\">\n</div>","css":".card img {\n  max-width: 100%;\n  height: 160px;\n  object-fit: cover;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, 11
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-grid-basics',
    '{"en":"CSS Grid: Multi-Column Layouts","de":"CSS Grid: Mehrspaltige Layouts"}'::jsonb,
    '[{"step":1,"text":{"en":"display: grid turns an element into a grid container. grid-template-columns defines how many columns and their widths.","de":"display: grid macht aus einem Element einen Grid-Container. grid-template-columns legt fest, wie viele Spalten es gibt und wie breit sie sind."}},{"step":2,"text":{"en":"Grid is perfect for laying out cards side by side — like a row of features or products.","de":"Grid eignet sich perfekt, um Karten nebeneinander anzuordnen — etwa eine Reihe von Features oder Produkten."}},{"step":3,"text":{"en":"Lay out three feature cards side by side using CSS Grid.","de":"Ordne drei Feature-Karten mit CSS Grid nebeneinander an."}}]'::jsonb,
    '{"html":"<div class=\"features\">\n  <div class=\"feature\">Fast</div>\n  <div class=\"feature\">Simple</div>\n  <div class=\"feature\">Free</div>\n</div>","css":".features {\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  gap: 20px;\n}\n\n.feature {\n  background: #111827;\n  color: white;\n  padding: 20px;\n  text-align: center;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, 12
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-forms-basics',
    '{"en":"Forms: Collecting Input","de":"Formulare: Eingaben sammeln"}'::jsonb,
    '[{"step":1,"text":{"en":"<input> collects text from a visitor. <label> describes what an input is for — important for accessibility.","de":"<input> sammelt Text von einem Besucher. <label> beschreibt, wofür ein Eingabefeld da ist — wichtig für Barrierefreiheit."}},{"step":2,"text":{"en":"<button> submits the form.","de":"<button> sendet das Formular ab."}},{"step":3,"text":{"en":"Build a simple contact form with a name field, an email field, and a submit button.","de":"Baue ein einfaches Kontaktformular mit einem Namensfeld, einem E-Mail-Feld und einem Absenden-Button."}}]'::jsonb,
    '{"html":"<form>\n  <label for=\"name\">Name</label>\n  <input id=\"name\" type=\"text\">\n\n  <label for=\"email\">Email</label>\n  <input id=\"email\" type=\"email\">\n\n  <button type=\"submit\">Send</button>\n</form>","css":"form {\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n  max-width: 240px;\n}\n\ninput, button {\n  padding: 8px;\n}"}'::jsonb,
    'beginner', true, 13
  ),
  (
    (select id from courses where slug = 'frontend'),
    'buttons-hover-transitions',
    '{"en":"Interactive Buttons: Hover & Transitions","de":"Interaktive Buttons: Hover & Übergänge"}'::jsonb,
    '[{"step":1,"text":{"en":":hover applies styles only while the mouse is over an element.","de":":hover wendet Styles nur an, solange sich die Maus über einem Element befindet."}},{"step":2,"text":{"en":"transition makes style changes (like color or size) happen smoothly instead of instantly.","de":"transition lässt Style-Änderungen (wie Farbe oder Größe) sanft statt sofort ablaufen."}},{"step":3,"text":{"en":"Give this button a hover effect with a smooth transition.","de":"Gib diesem Button einen Hover-Effekt mit einem sanften Übergang."}}]'::jsonb,
    '{"html":"<button>Contact Me</button>","css":"button {\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  cursor: pointer;\n  transition: background 0.2s ease;\n}\n\nbutton:hover {\n  background: #22c55e;\n}"}'::jsonb,
    'beginner', true, 14
  ),
  (
    (select id from courses where slug = 'frontend'),
    'complete-webpage-project',
    '{"en":"Putting It All Together","de":"Alles zusammenfügen"}'::jsonb,
    '[{"step":1,"text":{"en":"You now know structure (HTML), layout (Flexbox/Grid), and styling (CSS) — everything a real webpage needs.","de":"Du kennst jetzt Struktur (HTML), Layout (Flexbox/Grid) und Gestaltung (CSS) — alles, was eine echte Webseite braucht."}},{"step":2,"text":{"en":"A complete page usually has: header/nav, a hero, 2-3 content sections, and a footer.","de":"Eine vollständige Seite hat meist: Header/Nav, eine Hero-Section, 2-3 Inhaltsabschnitte und einen Footer."}},{"step":3,"text":{"en":"Combine everything you''ve built so far into one complete, styled webpage.","de":"Kombiniere alles, was du bisher gebaut hast, zu einer vollständigen, gestalteten Webseite."}}]'::jsonb,
    '{"html":"<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a> <a href=\"#\">Contact</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>Skills</h2>\n  <p>HTML, CSS, JavaScript</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\nfooter {\n  text-align: center;\n  color: #888;\n  margin-top: 40px;\n}"}'::jsonb,
    'beginner', true, 15
  ),
  (
    (select id from courses where slug = 'frontend'),
    'frontend-free-exam',
    '{"en":"Exam: Build a Complete Website","de":"Prüfung: Baue eine vollständige Website"}'::jsonb,
    '[{"step":1,"text":{"en":"This is your Frontend exam. Build a complete website using only HTML and CSS — no JavaScript yet.","de":"Das ist deine Frontend-Prüfung. Baue eine vollständige Website nur mit HTML und CSS — noch kein JavaScript."}},{"step":2,"text":{"en":"Requirements: a header with navigation, a hero section, at least two content sections, an image, and a footer.","de":"Anforderungen: ein Header mit Navigation, eine Hero-Section, mindestens zwei Inhaltsabschnitte, ein Bild und ein Footer."}},{"step":3,"text":{"en":"Make it responsive: it should still look good on a narrow screen. When you''re happy with it, mark your practice complete and submit the quiz.","de":"Mach sie responsive: Sie sollte auch auf einem schmalen Bildschirm gut aussehen. Wenn du zufrieden bist, markiere die Übung als erledigt und sende das Quiz ab."}}]'::jsonb,
    '{"html":"<!-- Build your complete website here -->\n<header>\n  <nav></nav>\n</header>","css":"/* Style your complete website here */"}'::jsonb,
    'intermediate', true, 16
  )
on conflict (slug) do nothing;

-- ── Backend: first 8 free lessons ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'backend'),
    'what-happens-when-you-open-a-website',
    '{"en":"What Happens When You Open a Website?","de":"Was passiert, wenn du eine Website öffnest?"}'::jsonb,
    '[{"step":1,"text":{"en":"When a user opens a website, their browser sends a request.","de":"Wenn ein Nutzer eine Website öffnet, sendet sein Browser eine Anfrage."}},{"step":2,"text":{"en":"A server receives the request, processes it, and sends back a response.","de":"Ein Server empfängt die Anfrage, verarbeitet sie und sendet eine Antwort zurück."}},{"step":3,"text":{"en":"That journey — frontend, backend, database, backend, frontend — is what the rest of this course is about.","de":"Diese Reise — Frontend, Backend, Datenbank, Backend, Frontend — ist das Thema des restlichen Kurses."}}]'::jsonb,
    null,
    'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'backend'),
    'creating-your-first-server',
    '{"en":"Creating Your First Server","de":"Deinen ersten Server erstellen"}'::jsonb,
    '[{"step":1,"text":{"en":"A server is a program that waits for requests and sends back responses. It is always running, listening.","de":"Ein Server ist ein Programm, das auf Anfragen wartet und Antworten zurücksendet. Er läuft ständig und hört zu."}},{"step":2,"text":{"en":"When a browser visits a path like /hello, the server decides what to send back.","de":"Wenn ein Browser einen Pfad wie /hello aufruft, entscheidet der Server, was er zurücksendet."}},{"step":3,"text":{"en":"Below is a JavaScript function that acts like a tiny server. Run it and check the console — then try changing what /hello returns.","de":"Unten ist eine JavaScript-Funktion, die wie ein kleiner Server funktioniert. Führe sie aus und schau in die Konsole — ändere dann, was /hello zurückgibt."}}]'::jsonb,
    '{"js":"function handleRequest(path) {\n  if (path === \"/hello\") {\n    return \"Hello Student\";\n  }\n  return \"404 Not Found\";\n}\n\nconsole.log(handleRequest(\"/hello\"));"}'::jsonb,
    'beginner', true, 2
  ),
  (
    (select id from courses where slug = 'backend'),
    'frontend-backend-connection',
    '{"en":"Frontend Asks, Backend Answers","de":"Frontend fragt, Backend antwortet"}'::jsonb,
    '[{"step":1,"text":{"en":"In a real app, the frontend (browser) sends a request, and the backend (server) sends back data — like a message or a list of users.","de":"In einer echten App sendet das Frontend (Browser) eine Anfrage, und das Backend (Server) sendet Daten zurück — etwa eine Nachricht oder eine Liste von Nutzern."}},{"step":2,"text":{"en":"This request-response pattern is the foundation of almost everything on the internet.","de":"Dieses Anfrage-Antwort-Muster ist die Grundlage für fast alles im Internet."}},{"step":3,"text":{"en":"Simulate it: this getMessage() function returns what a backend would send to the frontend. Run it and check the console.","de":"Simuliere es: Diese getMessage()-Funktion gibt zurück, was ein Backend an das Frontend senden würde. Führe sie aus und schau in die Konsole."}}]'::jsonb,
    '{"js":"function getMessage() {\n  return \"Welcome to CodePath Academy\";\n}\n\nconsole.log(getMessage());"}'::jsonb,
    'beginner', true, 3
  ),
  (
    (select id from courses where slug = 'backend'),
    'nodejs-introduction',
    '{"en":"Node.js: JavaScript Outside the Browser","de":"Node.js: JavaScript außerhalb des Browsers"}'::jsonb,
    '[{"step":1,"text":{"en":"You already know JavaScript from the frontend. Node.js lets that same language run on a server, not just in a browser.","de":"Du kennst JavaScript schon vom Frontend. Node.js lässt dieselbe Sprache auf einem Server laufen, nicht nur im Browser."}},{"step":2,"text":{"en":"This means the language you learned for buttons and forms can also handle requests, files, and databases.","de":"Das bedeutet: Die Sprache, die du für Buttons und Formulare gelernt hast, kann auch Anfragen, Dateien und Datenbanken verarbeiten."}},{"step":3,"text":{"en":"There is no browser here — just JavaScript logic. Run this function, then add a fourth username to the list.","de":"Hier gibt es keinen Browser — nur JavaScript-Logik. Führe diese Funktion aus und füge dann einen vierten Nutzernamen zur Liste hinzu."}}]'::jsonb,
    '{"js":"function getUsers() {\n  return [\"Ahmed\", \"Sara\", \"Lina\"];\n}\n\nconsole.log(getUsers());"}'::jsonb,
    'beginner', true, 4
  ),
  (
    (select id from courses where slug = 'backend'),
    'express-routes-intro',
    '{"en":"Routes: Answering Different Requests","de":"Routen: Verschiedene Anfragen beantworten"}'::jsonb,
    '[{"step":1,"text":{"en":"A real server needs to handle many different paths — /users, /login, /products — each with its own response. These are called routes.","de":"Ein echter Server muss viele verschiedene Pfade verarbeiten — /users, /login, /products — jeder mit einer eigenen Antwort. Das nennt man Routen."}},{"step":2,"text":{"en":"Express is a popular tool that makes defining routes simple. You will use it for real once you have this mental model down.","de":"Express ist ein beliebtes Tool, das das Definieren von Routen einfach macht. Du wirst es später wirklich nutzen, sobald du dieses Grundprinzip verstanden hast."}},{"step":3,"text":{"en":"This router(path) function simulates routing. Run it, then add a new route for /login.","de":"Diese router(path)-Funktion simuliert Routing. Führe sie aus und füge dann eine neue Route für /login hinzu."}}]'::jsonb,
    '{"js":"function router(path) {\n  if (path === \"/users\") return [\"Ahmed\", \"Sara\"];\n  if (path === \"/products\") return [\"Laptop\", \"Mouse\"];\n  return \"Not Found\";\n}\n\nconsole.log(router(\"/users\"));\nconsole.log(router(\"/products\"));"}'::jsonb,
    'beginner', true, 5
  ),
  (
    (select id from courses where slug = 'backend'),
    'building-an-api-endpoint',
    '{"en":"Building an API Endpoint","de":"Einen API-Endpunkt bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"An API endpoint is a specific URL a frontend can call to get or send data — like /api/users returning a list of users.","de":"Ein API-Endpunkt ist eine bestimmte URL, die ein Frontend aufrufen kann, um Daten zu holen oder zu senden — z. B. gibt /api/users eine Liste von Nutzern zurück."}},{"step":2,"text":{"en":"JSON (JavaScript Object Notation) is the format almost all APIs use to send data — it looks just like JavaScript objects.","de":"JSON (JavaScript Object Notation) ist das Format, das fast alle APIs zum Senden von Daten nutzen — es sieht genauso aus wie JavaScript-Objekte."}},{"step":3,"text":{"en":"This simulates an API endpoint. Run it, then add an email field to each user.","de":"Das simuliert einen API-Endpunkt. Führe es aus und füge dann jedem Nutzer ein E-Mail-Feld hinzu."}}]'::jsonb,
    '{"js":"function getUsersEndpoint() {\n  return [\n    { id: 1, name: \"Ahmed\" },\n    { id: 2, name: \"Sara\" }\n  ];\n}\n\nconsole.log(JSON.stringify(getUsersEndpoint(), null, 2));"}'::jsonb,
    'beginner', true, 6
  ),
  (
    (select id from courses where slug = 'backend'),
    'why-databases-exist',
    '{"en":"Why Databases Exist","de":"Warum es Datenbanken gibt"}'::jsonb,
    '[{"step":1,"text":{"en":"Without a database, information disappears the moment your program stops running. A database stores it permanently.","de":"Ohne Datenbank verschwinden Informationen, sobald dein Programm nicht mehr läuft. Eine Datenbank speichert sie dauerhaft."}},{"step":2,"text":{"en":"A database organizes data into tables — think of a table like a spreadsheet, with rows and columns.","de":"Eine Datenbank organisiert Daten in Tabellen — stell dir eine Tabelle wie eine Kalkulationstabelle mit Zeilen und Spalten vor."}},{"step":3,"text":{"en":"This array represents a ''users'' table with 2 rows. Run it, then add a third user row.","de":"Dieses Array stellt eine „users“-Tabelle mit 2 Zeilen dar. Führe es aus und füge dann eine dritte Nutzerzeile hinzu."}}]'::jsonb,
    '{"js":"const usersTable = [\n  { id: 1, name: \"Ahmed\", email: \"ahmed@example.com\" },\n  { id: 2, name: \"Sara\", email: \"sara@example.com\" }\n];\n\nconsole.log(usersTable);"}'::jsonb,
    'beginner', true, 7
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-free-exam',
    '{"en":"Exam: Design a Simple API","de":"Prüfung: Entwirf eine einfache API"}'::jsonb,
    '[{"step":1,"text":{"en":"This is your Backend foundations check. You will not run a real server yet — but you will design one.","de":"Das ist deine Backend-Grundlagenprüfung. Du wirst noch keinen echten Server betreiben — aber einen entwerfen."}},{"step":2,"text":{"en":"Requirements: write a router(path) function with at least 3 routes, and a getUsersEndpoint() function that returns JSON-shaped data.","de":"Anforderungen: Schreibe eine router(path)-Funktion mit mindestens 3 Routen und eine getUsersEndpoint()-Funktion, die JSON-förmige Daten zurückgibt."}},{"step":3,"text":{"en":"This is exactly the mental model real backend frameworks like Express use — you already understand it.","de":"Das ist genau das Grundprinzip, das echte Backend-Frameworks wie Express verwenden — du verstehst es schon."}}]'::jsonb,
    '{"js":"// Write your router(path) function and getUsersEndpoint() function here\n"}'::jsonb,
    'intermediate', true, 8
  )
on conflict (slug) do nothing;

-- ── Quiz questions (one per lesson that has one) ─────────────────────────

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
values
  (
    (select id from lessons where slug = 'html-hello-world'),
    '{"en":"What does HTML control on a website?","de":"Was steuert HTML auf einer Website?"}'::jsonb,
    '{"en":["The database","The structure and content","The server","The payment system"],"de":["Die Datenbank","Die Struktur und den Inhalt","Den Server","Das Zahlungssystem"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-styling-basics'),
    '{"en":"What does CSS control?","de":"Was steuert CSS?"}'::jsonb,
    '{"en":["The database","Website design","The server","User accounts"],"de":["Die Datenbank","Das Design der Website","Den Server","Benutzerkonten"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-css-div-profile-card'),
    '{"en":"What does the border-radius property do?","de":"Was macht die Eigenschaft border-radius?"}'::jsonb,
    '{"en":["Adds a shadow","Rounds the corners of an element","Changes text color","Adds a border image"],"de":["Fügt einen Schatten hinzu","Rundet die Ecken eines Elements ab","Ändert die Textfarbe","Fügt ein Rahmenbild hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'website-structure-nav-footer'),
    '{"en":"What does display: flex do?","de":"Was macht display: flex?"}'::jsonb,
    '{"en":["Deletes an element","Arranges child elements in a row (or column)","Makes text bold","Adds a border"],"de":["Löscht ein Element","Ordnet Kindelemente in einer Reihe (oder Spalte) an","Macht Text fett","Fügt einen Rahmen hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'flexbox-layout-basics'),
    '{"en":"Which property adds space between flex items?","de":"Welche Eigenschaft fügt Abstand zwischen Flex-Elementen hinzu?"}'::jsonb,
    '{"en":["space","margin-all","gap","spacing"],"de":["space","margin-all","gap","spacing"]}'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'semantic-html-sections'),
    '{"en":"Which tag best marks the main content of a page?","de":"Welches Tag markiert den Hauptinhalt einer Seite am besten?"}'::jsonb,
    '{"en":["<div>","<main>","<span>","<b>"],"de":["<div>","<main>","<span>","<b>"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'typography-basics'),
    '{"en":"What does line-height control?","de":"Was steuert line-height?"}'::jsonb,
    '{"en":["Font color","Space between lines of text","Font size","Text alignment"],"de":["Die Schriftfarbe","Den Abstand zwischen Textzeilen","Die Schriftgröße","Die Textausrichtung"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'box-model-deep-dive'),
    '{"en":"What is the difference between margin and padding?","de":"Was ist der Unterschied zwischen margin und padding?"}'::jsonb,
    '{"en":["No difference","Margin is inside the border, padding is outside","Padding is inside the border, margin is outside","Margin only works on text"],"de":["Kein Unterschied","Margin ist innerhalb des Rahmens, Padding außerhalb","Padding ist innerhalb des Rahmens, Margin außerhalb","Margin funktioniert nur bei Text"]}'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'hero-section'),
    '{"en":"What is a \"hero section\"?","de":"Was ist eine „Hero-Section“?"}'::jsonb,
    '{"en":["The website''s footer","A large introductory section at the top of a page","A navigation menu","A contact form"],"de":["Der Footer der Website","Ein großer einleitender Bereich oben auf einer Seite","Ein Navigationsmenü","Ein Kontaktformular"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'landing-page-assembly'),
    '{"en":"What usually comes first on a landing page?","de":"Was kommt auf einer Landingpage normalerweise zuerst?"}'::jsonb,
    '{"en":["The footer","A hero section","A login form","A database"],"de":["Der Footer","Eine Hero-Section","Ein Login-Formular","Eine Datenbank"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'responsive-images'),
    '{"en":"What does max-width: 100% do on an image?","de":"Was bewirkt max-width: 100% bei einem Bild?"}'::jsonb,
    '{"en":["Makes it always 100px wide","Stops it from growing wider than its container","Deletes the image","Adds a border"],"de":["Macht es immer 100px breit","Verhindert, dass es breiter als sein Container wird","Löscht das Bild","Fügt einen Rahmen hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-grid-basics'),
    '{"en":"Which property sets the number of grid columns?","de":"Welche Eigenschaft legt die Anzahl der Grid-Spalten fest?"}'::jsonb,
    '{"en":["grid-columns","grid-template-columns","column-count","display: columns"],"de":["grid-columns","grid-template-columns","column-count","display: columns"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-forms-basics'),
    '{"en":"What is <label> used for?","de":"Wofür wird <label> verwendet?"}'::jsonb,
    '{"en":["Styling a button","Describing what a form field is for","Creating a link","Adding an image"],"de":["Um einen Button zu gestalten","Um zu beschreiben, wofür ein Formularfeld da ist","Um einen Link zu erstellen","Um ein Bild hinzuzufügen"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'buttons-hover-transitions'),
    '{"en":"When does a :hover style apply?","de":"Wann gilt ein :hover-Style?"}'::jsonb,
    '{"en":["Always","Only while the mouse is over the element","Only on page load","Never in modern browsers"],"de":["Immer","Nur solange sich die Maus über dem Element befindet","Nur beim Laden der Seite","Nie in modernen Browsern"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'complete-webpage-project'),
    '{"en":"Which of these is NOT typically part of a complete webpage?","de":"Was gehört normalerweise NICHT zu einer vollständigen Webseite?"}'::jsonb,
    '{"en":["Header","Footer","Hero section","Database schema"],"de":["Header","Footer","Hero-Section","Datenbankschema"]}'::jsonb, 3, 1
  ),
  (
    (select id from lessons where slug = 'frontend-free-exam'),
    '{"en":"Why does this exam not use JavaScript yet?","de":"Warum verwendet diese Prüfung noch kein JavaScript?"}'::jsonb,
    '{"en":["JavaScript does not work in browsers","You first master structure (HTML) and design (CSS) before adding behavior","JavaScript is only for backend","CSS can replace JavaScript entirely"],"de":["JavaScript funktioniert nicht in Browsern","Du beherrschst zuerst Struktur (HTML) und Design (CSS), bevor Verhalten dazukommt","JavaScript ist nur für Backend","CSS kann JavaScript vollständig ersetzen"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'creating-your-first-server'),
    '{"en":"What does a server do when it receives a request?","de":"Was macht ein Server, wenn er eine Anfrage empfängt?"}'::jsonb,
    '{"en":["Deletes the browser","Processes it and sends back a response","Only stores passwords","Shows a CSS file"],"de":["Löscht den Browser","Verarbeitet sie und sendet eine Antwort zurück","Speichert nur Passwörter","Zeigt eine CSS-Datei"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'frontend-backend-connection'),
    '{"en":"In the request-response pattern, who sends the request?","de":"Wer sendet im Anfrage-Antwort-Muster die Anfrage?"}'::jsonb,
    '{"en":["The database","The frontend","The backend","The server itself"],"de":["Die Datenbank","Das Frontend","Das Backend","Der Server selbst"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'nodejs-introduction'),
    '{"en":"What is Node.js?","de":"Was ist Node.js?"}'::jsonb,
    '{"en":["A CSS framework","A way to run JavaScript outside the browser, e.g. on a server","A database","A design tool"],"de":["Ein CSS-Framework","Eine Möglichkeit, JavaScript außerhalb des Browsers auszuführen, z. B. auf einem Server","Eine Datenbank","Ein Design-Tool"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'express-routes-intro'),
    '{"en":"What is a \"route\" on a server?","de":"Was ist eine „Route“ auf einem Server?"}'::jsonb,
    '{"en":["A CSS class","A specific path the server knows how to respond to","A type of database","A browser tab"],"de":["Eine CSS-Klasse","Ein bestimmter Pfad, auf den der Server antworten kann","Eine Art Datenbank","Ein Browser-Tab"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'building-an-api-endpoint'),
    '{"en":"What format do most APIs use to send data?","de":"Welches Format verwenden die meisten APIs zum Senden von Daten?"}'::jsonb,
    '{"en":["CSS","JSON","HTML","MP3"],"de":["CSS","JSON","HTML","MP3"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'why-databases-exist'),
    '{"en":"What happens to data without a database?","de":"Was passiert mit Daten ohne Datenbank?"}'::jsonb,
    '{"en":["It becomes faster","It disappears when the program stops","It becomes more secure","Nothing changes"],"de":["Sie werden schneller","Sie verschwinden, wenn das Programm stoppt","Sie werden sicherer","Nichts ändert sich"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-free-exam'),
    '{"en":"What have routes and endpoints let you simulate in this lesson?","de":"Was konntest du mit Routen und Endpunkten in dieser Lektion simulieren?"}'::jsonb,
    '{"en":["A CSS animation","How a server responds differently to different requests","A database backup","An image gallery"],"de":["Eine CSS-Animation","Wie ein Server unterschiedlich auf verschiedene Anfragen reagiert","Ein Datenbank-Backup","Eine Bildergalerie"]}'::jsonb, 1, 1
  )
on conflict (lesson_id, question) do nothing;
