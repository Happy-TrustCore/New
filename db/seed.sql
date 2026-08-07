-- CodePath Academy — initial course content
-- Run this after db/schema.sql. This is the real (if early) curriculum:
-- Foundation (2 lessons), the first 16 free Frontend lessons, and the first
-- 8 free Backend lessons — enough to take a student from zero through a
-- complete HTML/CSS site and a working mental model of how servers work.
-- More lessons can be added later through the admin panel at /admin.

insert into courses (slug, title, description, sort_order) values
  ('foundation', 'Foundation', 'Understand how code and the web work.', 1),
  ('frontend', 'Frontend Development', 'HTML, CSS, JavaScript and React — one growing project.', 2),
  ('backend', 'Backend Development', 'Servers, Node.js, databases and authentication.', 3)
on conflict (slug) do nothing;

-- ── Foundation ────────────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'foundation'),
    'how-programming-works',
    'How Programming Works',
    '[
      {"step": 1, "text": "A computer only follows exact instructions. Programming is the act of writing those instructions in a language it understands."},
      {"step": 2, "text": "Every app you use — a website, a game, a banking app — is just instructions, run one after another."},
      {"step": 3, "text": "In this course you will write real instructions yourself, starting with the language browsers understand: HTML."}
    ]'::jsonb,
    null, 'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'foundation'),
    'how-websites-work',
    'How Websites Work',
    '[
      {"step": 1, "text": "When you open a website, your browser sends a request out to a server somewhere else in the world."},
      {"step": 2, "text": "The server sends back files — HTML, CSS, JavaScript — and your browser turns them into the page you see."},
      {"step": 3, "text": "Frontend is everything the browser shows you. Backend is everything happening on that server. You will build both."}
    ]'::jsonb,
    null, 'beginner', true, 2
  )
on conflict (slug) do nothing;

-- ── Frontend: 16 free lessons ────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'frontend'),
    'html-hello-world',
    'HTML: Your First Website',
    '[
      {"step": 1, "text": "HTML creates the structure and content of a website. There is no design yet — just content."},
      {"step": 2, "text": "<h1> creates a big heading. <p> creates a paragraph of text."},
      {"step": 3, "text": "Try changing the name in the heading below, then press Run to see your website update."}
    ]'::jsonb,
    '{"html": "<h1>Hello, my name is Ahmed</h1>\n<h2>I am learning coding</h2>\n<p>This is my first website.</p>"}'::jsonb,
    'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-styling-basics',
    'CSS: Styling Your Website',
    '[
      {"step": 1, "text": "CSS starts here — but your HTML does not restart. You are improving the same website from the last lesson."},
      {"step": 2, "text": "HTML creates the elements. CSS changes how they look: color, size, spacing."},
      {"step": 3, "text": "Try changing the color or font-size values below, then press Run."}
    ]'::jsonb,
    '{"html": "<h1>Hello, my name is Ahmed</h1>\n<p>This is my first website.</p>", "css": "h1 {\n  color: #34d399;\n}\n\np {\n  font-size: 20px;\n}"}'::jsonb,
    'beginner', true, 2
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-css-div-profile-card',
    'Building a Profile Card',
    '[
      {"step": 1, "text": "New HTML: <div> groups content together, and <img> shows a picture. Think of a <div> as a box you can style."},
      {"step": 2, "text": "New CSS: background-color fills a box with color. border adds an outline. padding adds space inside the box."},
      {"step": 3, "text": "Turn your name and role into a profile card: a box with a background, some padding, and rounded corners."}
    ]'::jsonb,
    '{"html": "<div class=\"card\">\n  <img src=\"https://placehold.co/80\" alt=\"Profile photo\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>", "css": ".card {\n  background-color: #111827;\n  color: white;\n  border: 1px solid #333;\n  border-radius: 12px;\n  padding: 20px;\n  width: 220px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, 3
  ),
  (
    (select id from courses where slug = 'frontend'),
    'website-structure-nav-footer',
    'Real Website Structure: Header, Nav, Footer',
    '[
      {"step": 1, "text": "New HTML: <nav> holds your navigation links. <footer> holds content at the bottom of the page, like copyright text."},
      {"step": 2, "text": "New CSS: display: flex arranges elements in a row instead of stacking them."},
      {"step": 3, "text": "Add a navigation bar with links, and a footer, to the profile card page you started."}
    ]'::jsonb,
    '{"html": "<header>\n  <nav>\n    <a href=\"#\">Home</a>\n    <a href=\"#\">About</a>\n    <a href=\"#\">Contact</a>\n  </nav>\n</header>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>", "css": "nav {\n  display: flex;\n  gap: 16px;\n}\n\nnav a {\n  color: #34d399;\n  text-decoration: none;\n}\n\nfooter {\n  margin-top: 40px;\n  color: #888;\n  font-size: 14px;\n}"}'::jsonb,
    'beginner', true, 4
  ),
  (
    (select id from courses where slug = 'frontend'),
    'flexbox-layout-basics',
    'Flexbox: Arranging Elements',
    '[
      {"step": 1, "text": "Flexbox controls how elements line up. justify-content controls horizontal spacing. align-items controls vertical alignment."},
      {"step": 2, "text": "gap adds space between flex items without needing margin on each one."},
      {"step": 3, "text": "Arrange your nav links with space between them, and center your profile card on the page."}
    ]'::jsonb,
    '{"html": "<nav>\n  <a href=\"#\">Home</a>\n  <a href=\"#\">About</a>\n  <a href=\"#\">Contact</a>\n</nav>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>", "css": "nav {\n  display: flex;\n  justify-content: space-between;\n  gap: 16px;\n}\n\nbody {\n  display: flex;\n  flex-direction: column;\n  align-items: center;\n}"}'::jsonb,
    'beginner', true, 5
  ),
  (
    (select id from courses where slug = 'frontend'),
    'semantic-html-sections',
    'Semantic HTML: main, section, article',
    '[
      {"step": 1, "text": "<main> marks the primary content of the page. <section> groups a themed chunk of content. <article> is a self-contained piece of content."},
      {"step": 2, "text": "Using the right tag (instead of always <div>) helps browsers, search engines, and screen readers understand your page."},
      {"step": 3, "text": "Wrap your profile card in a <main>, and add a new <section> introducing your skills."}
    ]'::jsonb,
    '{"html": "<main>\n  <div class=\"card\">\n    <h2>Ahmed</h2>\n    <p>Developer</p>\n  </div>\n\n  <section>\n    <h3>Skills</h3>\n    <p>HTML, CSS, JavaScript</p>\n  </section>\n</main>", "css": "section {\n  margin-top: 24px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, 6
  ),
  (
    (select id from courses where slug = 'frontend'),
    'typography-basics',
    'Typography: Fonts That Feel Professional',
    '[
      {"step": 1, "text": "font-family sets the typeface. font-weight controls boldness. line-height controls space between lines of text."},
      {"step": 2, "text": "Good typography is one of the fastest ways to make a website look professional."},
      {"step": 3, "text": "Update your page fonts: a bold heading, and a comfortable line-height for paragraphs."}
    ]'::jsonb,
    '{"html": "<h2>Ahmed</h2>\n<p>I build websites that work well and look great. Learning to code, one project at a time.</p>", "css": "h2 {\n  font-family: Georgia, serif;\n  font-weight: 700;\n}\n\np {\n  font-family: Arial, sans-serif;\n  line-height: 1.6;\n}"}'::jsonb,
    'beginner', true, 7
  ),
  (
    (select id from courses where slug = 'frontend'),
    'box-model-deep-dive',
    'The Box Model: Margin vs Padding',
    '[
      {"step": 1, "text": "Every HTML element is a box. padding is space INSIDE the border. margin is space OUTSIDE the border, between elements."},
      {"step": 2, "text": "box-sizing: border-box makes width and height include padding and border, which avoids surprises."},
      {"step": 3, "text": "Adjust the spacing on this card using margin and padding correctly."}
    ]'::jsonb,
    '{"html": "<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>", "css": "* {\n  box-sizing: border-box;\n}\n\n.card {\n  margin: 20px;\n  padding: 20px;\n  border: 1px solid #333;\n  width: 240px;\n}"}'::jsonb,
    'beginner', true, 8
  ),
  (
    (select id from courses where slug = 'frontend'),
    'hero-section',
    'Building a Hero Section',
    '[
      {"step": 1, "text": "A hero section is the big, eye-catching area at the top of a landing page: a large heading, short text, and a button."},
      {"step": 2, "text": "A large font-size on the heading and a call-to-action button draw the visitor''s attention immediately."},
      {"step": 3, "text": "Build a hero section for your own site: your name, a one-line pitch, and a button."}
    ]'::jsonb,
    '{"html": "<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n  <button>Contact Me</button>\n</section>", "css": ".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\n.hero h1 {\n  font-size: 48px;\n}\n\n.hero button {\n  margin-top: 16px;\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  font-weight: 600;\n  cursor: pointer;\n}"}'::jsonb,
    'beginner', true, 9
  ),
  (
    (select id from courses where slug = 'frontend'),
    'landing-page-assembly',
    'Assembling a Landing Page',
    '[
      {"step": 1, "text": "A landing page combines everything so far: header + nav, a hero section, a features/about section, and a footer."},
      {"step": 2, "text": "This is where your project stops being ''a page with stuff on it'' and starts being a real website."},
      {"step": 3, "text": "Combine your hero, an about section, and a footer into one flowing page."}
    ]'::jsonb,
    '{"html": "<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>About Me</h2>\n  <p>I''m learning to code with CodePath Academy.</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>", "css": ".hero {\n  text-align: center;\n  padding: 60px 20px;\n}"}'::jsonb,
    'beginner', true, 10
  ),
  (
    (select id from courses where slug = 'frontend'),
    'responsive-images',
    'Responsive Images',
    '[
      {"step": 1, "text": "max-width: 100% stops an image from overflowing its container on small screens."},
      {"step": 2, "text": "object-fit: cover crops an image neatly to fill a fixed-size box without stretching it."},
      {"step": 3, "text": "Make the image in your card responsive."}
    ]'::jsonb,
    '{"html": "<div class=\"card\">\n  <img src=\"https://placehold.co/400x200\" alt=\"Cover\">\n</div>", "css": ".card img {\n  max-width: 100%;\n  height: 160px;\n  object-fit: cover;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, 11
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-grid-basics',
    'CSS Grid: Multi-Column Layouts',
    '[
      {"step": 1, "text": "display: grid turns an element into a grid container. grid-template-columns defines how many columns and their widths."},
      {"step": 2, "text": "Grid is perfect for laying out cards side by side — like a row of features or products."},
      {"step": 3, "text": "Lay out three feature cards side by side using CSS Grid."}
    ]'::jsonb,
    '{"html": "<div class=\"features\">\n  <div class=\"feature\">Fast</div>\n  <div class=\"feature\">Simple</div>\n  <div class=\"feature\">Free</div>\n</div>", "css": ".features {\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  gap: 20px;\n}\n\n.feature {\n  background: #111827;\n  color: white;\n  padding: 20px;\n  text-align: center;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, 12
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-forms-basics',
    'Forms: Collecting Input',
    '[
      {"step": 1, "text": "<input> collects text from a visitor. <label> describes what an input is for — important for accessibility."},
      {"step": 2, "text": "<button> submits the form."},
      {"step": 3, "text": "Build a simple contact form with a name field, an email field, and a submit button."}
    ]'::jsonb,
    '{"html": "<form>\n  <label for=\"name\">Name</label>\n  <input id=\"name\" type=\"text\">\n\n  <label for=\"email\">Email</label>\n  <input id=\"email\" type=\"email\">\n\n  <button type=\"submit\">Send</button>\n</form>", "css": "form {\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n  max-width: 240px;\n}\n\ninput, button {\n  padding: 8px;\n}"}'::jsonb,
    'beginner', true, 13
  ),
  (
    (select id from courses where slug = 'frontend'),
    'buttons-hover-transitions',
    'Interactive Buttons: Hover & Transitions',
    '[
      {"step": 1, "text": ":hover applies styles only while the mouse is over an element."},
      {"step": 2, "text": "transition makes style changes (like color or size) happen smoothly instead of instantly."},
      {"step": 3, "text": "Give this button a hover effect with a smooth transition."}
    ]'::jsonb,
    '{"html": "<button>Contact Me</button>", "css": "button {\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  cursor: pointer;\n  transition: background 0.2s ease;\n}\n\nbutton:hover {\n  background: #22c55e;\n}"}'::jsonb,
    'beginner', true, 14
  ),
  (
    (select id from courses where slug = 'frontend'),
    'complete-webpage-project',
    'Putting It All Together',
    '[
      {"step": 1, "text": "You now know structure (HTML), layout (Flexbox/Grid), and styling (CSS) — everything a real webpage needs."},
      {"step": 2, "text": "A complete page usually has: header/nav, a hero, 2-3 content sections, and a footer."},
      {"step": 3, "text": "Combine everything you''ve built so far into one complete, styled webpage."}
    ]'::jsonb,
    '{"html": "<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a> <a href=\"#\">Contact</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>Skills</h2>\n  <p>HTML, CSS, JavaScript</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>", "css": ".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\nfooter {\n  text-align: center;\n  color: #888;\n  margin-top: 40px;\n}"}'::jsonb,
    'beginner', true, 15
  ),
  (
    (select id from courses where slug = 'frontend'),
    'frontend-free-exam',
    'Exam: Build a Complete Website',
    '[
      {"step": 1, "text": "This is your Frontend exam. Build a complete website using only HTML and CSS — no JavaScript yet."},
      {"step": 2, "text": "Requirements: a header with navigation, a hero section, at least two content sections, an image, and a footer."},
      {"step": 3, "text": "Make it responsive: it should still look good on a narrow screen. When you''re happy with it, mark your practice complete and submit the quiz."}
    ]'::jsonb,
    '{"html": "<!-- Build your complete website here -->\n<header>\n  <nav></nav>\n</header>", "css": "/* Style your complete website here */"}'::jsonb,
    'intermediate', true, 16
  )
on conflict (slug) do nothing;

-- ── Backend: first 8 free lessons ────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, sort_order)
values
  (
    (select id from courses where slug = 'backend'),
    'what-happens-when-you-open-a-website',
    'What Happens When You Open a Website?',
    '[
      {"step": 1, "text": "When a user opens a website, their browser sends a request."},
      {"step": 2, "text": "A server receives the request, processes it, and sends back a response."},
      {"step": 3, "text": "That journey — frontend, backend, database, backend, frontend — is what the rest of this course is about."}
    ]'::jsonb,
    null, 'beginner', true, 1
  ),
  (
    (select id from courses where slug = 'backend'),
    'creating-your-first-server',
    'Creating Your First Server',
    '[
      {"step": 1, "text": "A server is a program that waits for requests and sends back responses. It is always running, listening."},
      {"step": 2, "text": "When a browser visits a path like /hello, the server decides what to send back."},
      {"step": 3, "text": "Below is a JavaScript function that acts like a tiny server. Run it and check the console — then try changing what /hello returns."}
    ]'::jsonb,
    '{"js": "function handleRequest(path) {\n  if (path === \"/hello\") {\n    return \"Hello Student\";\n  }\n  return \"404 Not Found\";\n}\n\nconsole.log(handleRequest(\"/hello\"));"}'::jsonb,
    'beginner', true, 2
  ),
  (
    (select id from courses where slug = 'backend'),
    'frontend-backend-connection',
    'Frontend Asks, Backend Answers',
    '[
      {"step": 1, "text": "In a real app, the frontend (browser) sends a request, and the backend (server) sends back data — like a message or a list of users."},
      {"step": 2, "text": "This request-response pattern is the foundation of almost everything on the internet."},
      {"step": 3, "text": "Simulate it: this getMessage() function returns what a backend would send to the frontend. Run it and check the console."}
    ]'::jsonb,
    '{"js": "function getMessage() {\n  return \"Welcome to CodePath Academy\";\n}\n\nconsole.log(getMessage());"}'::jsonb,
    'beginner', true, 3
  ),
  (
    (select id from courses where slug = 'backend'),
    'nodejs-introduction',
    'Node.js: JavaScript Outside the Browser',
    '[
      {"step": 1, "text": "You already know JavaScript from the frontend. Node.js lets that same language run on a server, not just in a browser."},
      {"step": 2, "text": "This means the language you learned for buttons and forms can also handle requests, files, and databases."},
      {"step": 3, "text": "There is no browser here — just JavaScript logic. Run this function, then add a fourth username to the list."}
    ]'::jsonb,
    '{"js": "function getUsers() {\n  return [\"Ahmed\", \"Sara\", \"Lina\"];\n}\n\nconsole.log(getUsers());"}'::jsonb,
    'beginner', true, 4
  ),
  (
    (select id from courses where slug = 'backend'),
    'express-routes-intro',
    'Routes: Answering Different Requests',
    '[
      {"step": 1, "text": "A real server needs to handle many different paths — /users, /login, /products — each with its own response. These are called routes."},
      {"step": 2, "text": "Express is a popular tool that makes defining routes simple. You will use it for real once you have this mental model down."},
      {"step": 3, "text": "This router(path) function simulates routing. Run it, then add a new route for /login."}
    ]'::jsonb,
    '{"js": "function router(path) {\n  if (path === \"/users\") return [\"Ahmed\", \"Sara\"];\n  if (path === \"/products\") return [\"Laptop\", \"Mouse\"];\n  return \"Not Found\";\n}\n\nconsole.log(router(\"/users\"));\nconsole.log(router(\"/products\"));"}'::jsonb,
    'beginner', true, 5
  ),
  (
    (select id from courses where slug = 'backend'),
    'building-an-api-endpoint',
    'Building an API Endpoint',
    '[
      {"step": 1, "text": "An API endpoint is a specific URL a frontend can call to get or send data — like /api/users returning a list of users."},
      {"step": 2, "text": "JSON (JavaScript Object Notation) is the format almost all APIs use to send data — it looks just like JavaScript objects."},
      {"step": 3, "text": "This simulates an API endpoint. Run it, then add an email field to each user."}
    ]'::jsonb,
    '{"js": "function getUsersEndpoint() {\n  return [\n    { id: 1, name: \"Ahmed\" },\n    { id: 2, name: \"Sara\" }\n  ];\n}\n\nconsole.log(JSON.stringify(getUsersEndpoint(), null, 2));"}'::jsonb,
    'beginner', true, 6
  ),
  (
    (select id from courses where slug = 'backend'),
    'why-databases-exist',
    'Why Databases Exist',
    '[
      {"step": 1, "text": "Without a database, information disappears the moment your program stops running. A database stores it permanently."},
      {"step": 2, "text": "A database organizes data into tables — think of a table like a spreadsheet, with rows and columns."},
      {"step": 3, "text": "This array represents a ''users'' table with 2 rows. Run it, then add a third user row."}
    ]'::jsonb,
    '{"js": "const usersTable = [\n  { id: 1, name: \"Ahmed\", email: \"ahmed@example.com\" },\n  { id: 2, name: \"Sara\", email: \"sara@example.com\" }\n];\n\nconsole.log(usersTable);"}'::jsonb,
    'beginner', true, 7
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-free-exam',
    'Exam: Design a Simple API',
    '[
      {"step": 1, "text": "This is your Backend foundations check. You will not run a real server yet — but you will design one."},
      {"step": 2, "text": "Requirements: write a router(path) function with at least 3 routes, and a getUsersEndpoint() function that returns JSON-shaped data."},
      {"step": 3, "text": "This is exactly the mental model real backend frameworks like Express use — you already understand it."}
    ]'::jsonb,
    '{"js": "// Write your router(path) function and getUsersEndpoint() function here\n"}'::jsonb,
    'intermediate', true, 8
  )
on conflict (slug) do nothing;

-- ── Quiz questions (one per lesson) ──────────────────────────────────────

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
values
  (
    (select id from lessons where slug = 'html-hello-world'),
    'What does HTML control on a website?',
    '["The database", "The structure and content", "The server", "The payment system"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-styling-basics'),
    'What does CSS control?',
    '["The database", "Website design", "The server", "User accounts"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-css-div-profile-card'),
    'What does the border-radius property do?',
    '["Adds a shadow", "Rounds the corners of an element", "Changes text color", "Adds a border image"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'website-structure-nav-footer'),
    'What does display: flex do?',
    '["Deletes an element", "Arranges child elements in a row (or column)", "Makes text bold", "Adds a border"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'flexbox-layout-basics'),
    'Which property adds space between flex items?',
    '["space", "margin-all", "gap", "spacing"]'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'semantic-html-sections'),
    'Which tag best marks the main content of a page?',
    '["<div>", "<main>", "<span>", "<b>"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'typography-basics'),
    'What does line-height control?',
    '["Font color", "Space between lines of text", "Font size", "Text alignment"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'box-model-deep-dive'),
    'What is the difference between margin and padding?',
    '["No difference", "Margin is inside the border, padding is outside", "Padding is inside the border, margin is outside", "Margin only works on text"]'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'hero-section'),
    'What is a "hero section"?',
    '["The website''s footer", "A large introductory section at the top of a page", "A navigation menu", "A contact form"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'landing-page-assembly'),
    'What usually comes first on a landing page?',
    '["The footer", "A hero section", "A login form", "A database"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'responsive-images'),
    'What does max-width: 100% do on an image?',
    '["Makes it always 100px wide", "Stops it from growing wider than its container", "Deletes the image", "Adds a border"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-grid-basics'),
    'Which property sets the number of grid columns?',
    '["grid-columns", "grid-template-columns", "column-count", "display: columns"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-forms-basics'),
    'What is <label> used for?',
    '["Styling a button", "Describing what a form field is for", "Creating a link", "Adding an image"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'buttons-hover-transitions'),
    'When does a :hover style apply?',
    '["Always", "Only while the mouse is over the element", "Only on page load", "Never in modern browsers"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'complete-webpage-project'),
    'Which of these is NOT typically part of a complete webpage?',
    '["Header", "Footer", "Hero section", "Database schema"]'::jsonb, 3, 1
  ),
  (
    (select id from lessons where slug = 'frontend-free-exam'),
    'Why does this exam not use JavaScript yet?',
    '["JavaScript does not work in browsers", "You first master structure (HTML) and design (CSS) before adding behavior", "JavaScript is only for backend", "CSS can replace JavaScript entirely"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'creating-your-first-server'),
    'What does a server do when it receives a request?',
    '["Deletes the browser", "Processes it and sends back a response", "Only stores passwords", "Shows a CSS file"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'frontend-backend-connection'),
    'In the request-response pattern, who sends the request?',
    '["The database", "The frontend", "The backend", "The server itself"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'nodejs-introduction'),
    'What is Node.js?',
    '["A CSS framework", "A way to run JavaScript outside the browser, e.g. on a server", "A database", "A design tool"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'express-routes-intro'),
    'What is a "route" on a server?',
    '["A CSS class", "A specific path the server knows how to respond to", "A type of database", "A browser tab"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'building-an-api-endpoint'),
    'What format do most APIs use to send data?',
    '["CSS", "JSON", "HTML", "MP3"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'why-databases-exist'),
    'What happens to data without a database?',
    '["It becomes faster", "It disappears when the program stops", "It becomes more secure", "Nothing changes"]'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-free-exam'),
    'What have routes and endpoints let you simulate in this lesson?',
    '["A CSS animation", "How a server responds differently to different requests", "A database backup", "An image gallery"]'::jsonb, 1, 1
  )
on conflict (lesson_id, question) do nothing;
