BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "col" (
	"id"	integer,
	"crt"	integer NOT NULL,
	"mod"	integer NOT NULL,
	"scm"	integer NOT NULL,
	"ver"	integer NOT NULL,
	"dty"	integer NOT NULL,
	"usn"	integer NOT NULL,
	"ls"	integer NOT NULL,
	"conf"	text NOT NULL,
	"models"	text NOT NULL,
	"decks"	text NOT NULL,
	"dconf"	text NOT NULL,
	"tags"	text NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "notes" (
	"id"	integer,
	"guid"	text NOT NULL,
	"mid"	integer NOT NULL,
	"mod"	integer NOT NULL,
	"usn"	integer NOT NULL,
	"tags"	text NOT NULL,
	"flds"	text NOT NULL,
	"sfld"	integer NOT NULL,
	"csum"	integer NOT NULL,
	"flags"	integer NOT NULL,
	"data"	text NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "cards" (
	"id"	integer,
	"nid"	integer NOT NULL,
	"did"	integer NOT NULL,
	"ord"	integer NOT NULL,
	"mod"	integer NOT NULL,
	"usn"	integer NOT NULL,
	"type"	integer NOT NULL,
	"queue"	integer NOT NULL,
	"due"	integer NOT NULL,
	"ivl"	integer NOT NULL,
	"factor"	integer NOT NULL,
	"reps"	integer NOT NULL,
	"lapses"	integer NOT NULL,
	"left"	integer NOT NULL,
	"odue"	integer NOT NULL,
	"odid"	integer NOT NULL,
	"flags"	integer NOT NULL,
	"data"	text NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "revlog" (
	"id"	integer,
	"cid"	integer NOT NULL,
	"usn"	integer NOT NULL,
	"ease"	integer NOT NULL,
	"ivl"	integer NOT NULL,
	"lastIvl"	integer NOT NULL,
	"factor"	integer NOT NULL,
	"time"	integer NOT NULL,
	"type"	integer NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "graves" (
	"usn"	integer NOT NULL,
	"oid"	integer NOT NULL,
	"type"	integer NOT NULL
);
INSERT INTO "col" ("id","crt","mod","scm","ver","dty","usn","ls","conf","models","decks","dconf","tags") VALUES (1,1603483200,1622427474934,1622427474704,11,0,0,0,'{"nextPos":32,"schedVer":1,"sortBackwards":false,"activeDecks":[1],"localOffset":-720,"dayLearnFirst":false,"estTimes":true,"newSpread":0,"addToCur":true,"dueCounts":true,"collapseTime":1200,"curDeck":1,"timeLim":0,"curModel":1622287453372,"sortType":"noteFld"}','{"1622287453372":{"id":1622287453372,"name":"AsteroidPeopleBasic","type":0,"mod":1622427418,"usn":-1,"sortf":0,"did":1622285981071,"tmpls":[{"name":"Name -> About","ord":0,"qfmt":"<a href=\"{{URL}}\">{{Name}}</a> <small class=\"asteroid\">(<a href=\"{{Asteroid URL}}\">{{Asteroid Name}}</a>)</small>\n\n<hr>\n\n?\n","afmt":"<a href=\"{{URL}}\">{{Name}}</a> <small class=\"asteroid\">(<a href=\"{{Asteroid URL}}\">{{Asteroid Name}}</a>)</small>\n\n<div class=\"categories\">{{Categories}}</div>\n\n<hr>\n\n<div class=\"profile\">{{Image}}</div>\n<hr>\n\n<div class=\"description\">\n{{First Paragraph}}\n</div>","bqfmt":"","bafmt":"","did":null,"bfont":"","bsize":0},{"name":"Picture -> Name","ord":1,"qfmt":"<div class=\"profile\">{{Image}}</div>\n\n\n<hr>\n\n?","afmt":"<div class=\"profile\">{{Image}}</div>\n\n<hr>\n\n<a href=\"{{URL}}\">{{Name}}</a> <small class=\"asteroid\">(<a href=\"{{Asteroid URL}}\">{{Asteroid Name}}</a>)</small>\n\n<div class=\"categories\">{{Categories}}</div>\n<hr>\n\n<div class=\"description\">\n{{First Paragraph}}\n</div>","bqfmt":"","bafmt":"","did":null,"bfont":"","bsize":0}],"flds":[{"name":"Name","ord":0,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"URL","ord":1,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Asteroid Number","ord":2,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Asteroid Name","ord":3,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Asteroid URL","ord":4,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Categories","ord":5,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"First Paragraph","ord":6,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Image","ord":7,"sticky":false,"rtl":false,"font":"Arial","size":20}],"css":".card {\n  font-family: arial;\n  font-size: 20px;\n  text-align: center;\n  color: black;\n  background-color: white;\n}\n\n\nhr {\n  margin: 22px;\n}\n\nsmall.asteroid {\n  font-size: 14px;\n}\n\n.description {\n  text-align: left;\n  font-size: 16px;\n\tline-height: 21px;\n\tmax-width: 450px;\n  margin: auto;\n  margin-top: 25px\n}\n\n.profile {\n\tmargin: auto;\n}\n.profile img {\n  max-width: 300px;\n  max-height: 300px;\n}\n\n.categories {\n  font-size: 12px;\n  color: #777;\n  margin-top: 10px;\n}","latexPre":"\\documentclass[12pt]{article}\n\\special{papersize=3in,5in}\n\\usepackage[utf8]{inputenc}\n\\usepackage{amssymb,amsmath}\n\\pagestyle{empty}\n\\setlength{\\parindent}{0in}\n\\begin{document}\n","latexPost":"\\end{document}","latexsvg":false,"req":[[0,"any",[0,1,3,4]],[1,"any",[7]]]},"1622427474704":{"id":1622427474704,"name":"Basic","type":0,"mod":0,"usn":0,"sortf":0,"did":1,"tmpls":[{"name":"Card 1","ord":0,"qfmt":"{{Front}}","afmt":"{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}","bqfmt":"","bafmt":"","did":null,"bfont":"","bsize":0}],"flds":[{"name":"Front","ord":0,"sticky":false,"rtl":false,"font":"Arial","size":20},{"name":"Back","ord":1,"sticky":false,"rtl":false,"font":"Arial","size":20}],"css":".card {\n  font-family: arial;\n  font-size: 20px;\n  text-align: center;\n  color: black;\n  background-color: white;\n}\n","latexPre":"\\documentclass[12pt]{article}\n\\special{papersize=3in,5in}\n\\usepackage[utf8]{inputenc}\n\\usepackage{amssymb,amsmath}\n\\pagestyle{empty}\n\\setlength{\\parindent}{0in}\n\\begin{document}\n","latexPost":"\\end{document}","latexsvg":false,"req":[[0,"any",[0]]]}}','{"1":{"id":1,"mod":0,"name":"Default","usn":0,"lrnToday":[0,0],"revToday":[0,0],"newToday":[0,0],"timeToday":[0,0],"collapsed":true,"browserCollapsed":true,"desc":"","dyn":0,"conf":1,"extendNew":0,"extendRev":0},"1622285981071":{"id":1622285981071,"mod":1622427032,"name":"People With Asteroids Named After Them","usn":-1,"lrnToday":[218,0],"revToday":[218,0],"newToday":[218,20],"timeToday":[218,635958],"collapsed":true,"browserCollapsed":true,"desc":"This deck is a list of people who are famous enough to have an asteroid named after them. I scraped the data from the Wikipedia page for ''List of minor planets named after people'': https://en.wikipedia.org/wiki/List_of_minor_planets_named_after_people\n\nI have excluded any people that don''t have their own Wikipedia page, or where I couldn''t find a profile image. The lists includes a lot of famous scientists, historical figures, musicians, actors, and many others. However, you probably won''t want to memorize every single person on this list. Get ready to use the ''!'' keyboard shortcut to suspend any notes if you don''t care about certain people.","dyn":0,"mid":1622287453372,"conf":1,"extendNew":0,"extendRev":0}}','{"1":{"id":1,"mod":0,"name":"Default","usn":0,"maxTaken":60,"autoplay":true,"timer":0,"replayq":true,"new":{"bury":false,"delays":[1.0,10.0],"initialFactor":2500,"ints":[1,4,0],"order":1,"perDay":20},"rev":{"bury":false,"ease4":1.3,"ivlFct":1.0,"maxIvl":36500,"perDay":200,"hardFactor":1.2},"lapse":{"delays":[10.0],"leechAction":1,"leechFails":8,"minInt":1,"mult":0.0},"dyn":false,"newMix":0,"newPerDayMinimum":0,"interdayLearningMix":0,"reviewOrder":0}}','{}');
CREATE INDEX IF NOT EXISTS "ix_notes_usn" ON "notes" (
	"usn"
);
CREATE INDEX IF NOT EXISTS "ix_cards_usn" ON "cards" (
	"usn"
);
CREATE INDEX IF NOT EXISTS "ix_revlog_usn" ON "revlog" (
	"usn"
);
CREATE INDEX IF NOT EXISTS "ix_cards_nid" ON "cards" (
	"nid"
);
CREATE INDEX IF NOT EXISTS "ix_cards_sched" ON "cards" (
	"did",
	"queue",
	"due"
);
CREATE INDEX IF NOT EXISTS "ix_revlog_cid" ON "revlog" (
	"cid"
);
CREATE INDEX IF NOT EXISTS "ix_notes_csum" ON "notes" (
	"csum"
);
COMMIT;
