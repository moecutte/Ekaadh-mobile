import { useState, useEffect } from "react";
import {
  Home, Search, Ticket, User, Bell, MapPin, ChevronLeft, ChevronRight,
  X, Check, Share2, Download, Clock, Minus, Plus, Camera, Loader2,
  Wifi, Battery, Signal, Star, Zap, QrCode, CheckCircle, XCircle,
  AlarmClock, ShieldCheck, Shield, MessageCircle, Calendar,
} from "lucide-react";

type Screen =
  | "splash" | "onboarding" | "login" | "register"
  | "home" | "search" | "event-detail" | "ticket-selection"
  | "checkout" | "checkout-processing" | "checkout-failed"
  | "order-confirmation" | "my-tickets" | "ticket-view"
  | "profile"
  | "staff-login" | "staff-events" | "scanner" | "scan-valid" | "scan-used" | "scan-invalid";

const B = "#10b77f";
const BD = "#0d9468";
const BL = "#e8f7f1";
const DARK = "#0f1a15";

const EVENTS = [
  {
    id: "1",
    title: "Mogadishu Music Festival",
    date: "Jul 19, 2026",
    dm: { m: "JUL", d: "19" },
    time: "6:00 PM",
    venue: "Lido Beach Arena, Mogadishu",
    category: "Music",
    price: 15,
    image:
      "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&h=450&fit=crop&auto=format",
    description:
      "Somalia's biggest annual music festival returns for its 5th edition. Join 5,000+ fans for a night of live performances from top East African artists, DJs, and surprise international guests.\n\nGates open at 5 PM with food stalls, art installations, and cultural exhibits. Dress code: festive.\n\nLineup includes Ayaan, K'naan tribute sets, and three international headliners to be announced.",
  },
  {
    id: "2",
    title: "TEDx Mogadishu 2026",
    date: "Aug 2, 2026",
    dm: { m: "AUG", d: "2" },
    time: "9:00 AM",
    venue: "SYL Hotel Conference Centre",
    category: "Tech",
    price: 25,
    image:
      "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=450&fit=crop&auto=format",
    description:
      "Ideas worth spreading. Join thought leaders, innovators, and change-makers for a full day of inspiring talks on tech, medicine, social change, and entrepreneurship. Network over lunch and coffee.",
  },
  {
    id: "3",
    title: "Somali Premier League Finals",
    date: "Aug 15, 2026",
    dm: { m: "AUG", d: "15" },
    time: "5:00 PM",
    venue: "Banadir Stadium, Mogadishu",
    category: "Sports",
    price: 8,
    image:
      "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&h=450&fit=crop&auto=format",
    description:
      "The grandest match of the Somali football calendar. Watch the best two clubs battle for the championship title in front of 20,000 passionate fans.",
  },
  {
    id: "4",
    title: "Hargeisa Food & Culture Fest",
    date: "Sep 5, 2026",
    dm: { m: "SEP", d: "5" },
    time: "12:00 PM",
    venue: "Maansoor Hotel Grounds",
    category: "Food",
    price: 5,
    image:
      "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=450&fit=crop&auto=format",
    description:
      "Taste your way through Somalia's rich culinary heritage. Over 40 food stalls, live cooking demos, traditional music, and craft markets across three stages.",
  },
  {
    id: "5",
    title: "Comedy Night Mogadishu",
    date: "Jul 25, 2026",
    dm: { m: "JUL", d: "25" },
    time: "8:00 PM",
    venue: "Sahafi Hotel Ballroom",
    category: "Comedy",
    price: 10,
    image:
      "https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=800&h=450&fit=crop&auto=format",
    description:
      "Laugh out loud with the best stand-up comedians from across the Horn of Africa. An unforgettable evening of humor, wit, and cultural stories.",
  },
];

const CATS = ["All", "Music", "Sports", "Comedy", "Tech", "Food"];

// ─── QR Code (decorative) ────────────────────────────────────────────────────
function QRCodeSVG({ size = 160 }: { size?: number }) {
  const n = 21;
  const c = size / n;

  const px = (r: number, col: number): boolean => {
    if (r <= 6 && col <= 6) {
      if (r === 0 || r === 6 || col === 0 || col === 6) return true;
      if (r === 1 || r === 5 || col === 1 || col === 5) return false;
      return r >= 2 && r <= 4 && col >= 2 && col <= 4;
    }
    if (r <= 6 && col >= n - 7) {
      const lc = col - (n - 7);
      if (r === 0 || r === 6 || lc === 0 || lc === 6) return true;
      if (r === 1 || r === 5 || lc === 1 || lc === 5) return false;
      return r >= 2 && r <= 4 && lc >= 2 && lc <= 4;
    }
    if (r >= n - 7 && col <= 6) {
      const lr = r - (n - 7);
      if (lr === 0 || lr === 6 || col === 0 || col === 6) return true;
      if (lr === 1 || lr === 5 || col === 1 || col === 5) return false;
      return lr >= 2 && lr <= 4 && col >= 2 && col <= 4;
    }
    if (r === 6 && col > 7 && col < n - 8) return col % 2 === 0;
    if (col === 6 && r > 7 && r < n - 8) return r % 2 === 0;
    return ((r * 13 + col * 7 + (r ^ col)) % 2 === 0);
  };

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ borderRadius: 8 }}>
      <rect width={size} height={size} fill="white" rx={8} />
      {Array.from({ length: n }, (_, r) =>
        Array.from({ length: n }, (_, col) =>
          px(r, col) ? (
            <rect key={`${r}-${col}`} x={col * c + 0.3} y={r * c + 0.3} width={c - 0.6} height={c - 0.6} fill={DARK} />
          ) : null
        )
      )}
    </svg>
  );
}

// ─── Status Bar ───────────────────────────────────────────────────────────────
function StatusBar({ light = false }: { light?: boolean }) {
  const clr = light ? "white" : DARK;
  return (
    <div style={{ height: 50, color: clr }} className="flex items-center justify-between px-6 pt-4">
      <span style={{ fontSize: 13, fontWeight: 800 }}>9:41</span>
      <div style={{ width: 130 }} />
      <div className="flex items-center gap-1.5">
        <Signal size={12} />
        <Wifi size={12} />
        <Battery size={14} />
      </div>
    </div>
  );
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
function BottomNav({ active, nav }: { active: string; nav: (s: Screen) => void }) {
  const tabs = [
    { id: "home" as Screen, icon: Home, label: "Home" },
    { id: "search" as Screen, icon: Search, label: "Search" },
    { id: "my-tickets" as Screen, icon: Ticket, label: "Tickets" },
    { id: "profile" as Screen, icon: User, label: "Profile" },
  ];
  return (
    <div className="flex bg-white border-t border-gray-100 pt-2 pb-6">
      {tabs.map(({ id, icon: Icon, label }) => (
        <button key={id} onClick={() => nav(id)} className="flex-1 flex flex-col items-center gap-0.5">
          <Icon size={22} color={active === id ? B : "#b8bfbb"} strokeWidth={active === id ? 2.5 : 2} />
          <span style={{ fontSize: 10, fontWeight: 700, color: active === id ? B : "#b8bfbb" }}>{label}</span>
        </button>
      ))}
    </div>
  );
}

// ─── SPLASH ──────────────────────────────────────────────────────────────────
function SplashScreen({ nav }: { nav: (s: Screen) => void }) {
  useEffect(() => {
    const t = setTimeout(() => nav("onboarding"), 2200);
    return () => clearTimeout(t);
  }, [nav]);
  return (
    <div className="flex flex-col h-full" style={{ background: B }}>
      <StatusBar light />
      <div className="flex-1 flex flex-col items-center justify-center gap-6">
        <div
          className="flex items-center justify-center"
          style={{ width: 112, height: 112, background: "rgba(255,255,255,0.18)", borderRadius: 32, border: "1.5px solid rgba(255,255,255,0.3)" }}
        >
          <Ticket size={52} color="white" strokeWidth={1.8} />
        </div>
        <div className="text-center">
          <h1 style={{ fontSize: 48, fontWeight: 900, color: "white", letterSpacing: -1 }}>Ekaadh</h1>
          <p style={{ color: "rgba(255,255,255,0.65)", fontSize: 14, fontWeight: 500, letterSpacing: 1 }}>
            Your Event · Your Ticket
          </p>
        </div>
      </div>
      <div className="pb-14 flex justify-center gap-2">
        <div style={{ width: 28, height: 8, borderRadius: 4, background: "white" }} />
        <div style={{ width: 8, height: 8, borderRadius: 4, background: "rgba(255,255,255,0.35)" }} />
        <div style={{ width: 8, height: 8, borderRadius: 4, background: "rgba(255,255,255,0.35)" }} />
      </div>
    </div>
  );
}

// ─── ONBOARDING ───────────────────────────────────────────────────────────────
const SLIDES = [
  {
    emoji: "🎪",
    bg: BL,
    title: "Discover Amazing Events",
    body: "Browse concerts, sports, food festivals, and more happening near you — all in one place.",
  },
  {
    emoji: "⚡",
    bg: "#eff0fe",
    title: "Buy Tickets in Seconds",
    body: "Select your seats, choose Zaad or eDahab, and pay instantly. No cash, no queues.",
  },
  {
    emoji: "📱",
    bg: "#fffbeb",
    title: "Your Ticket, Always Ready",
    body: "Your QR-code tickets live in the app. Show them at the door — no printing needed.",
  },
];

function OnboardingScreen({ nav }: { nav: (s: Screen) => void }) {
  const [slide, setSlide] = useState(0);
  const s = SLIDES[slide];
  const isLast = slide === SLIDES.length - 1;
  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="flex justify-end px-5 pt-1">
        <button onClick={() => nav("login")} style={{ fontSize: 14, fontWeight: 700, color: "#b8bfbb" }}>
          Skip
        </button>
      </div>
      <div
        className="mx-5 mt-4 flex items-center justify-center"
        style={{ height: 290, borderRadius: 28, background: s.bg }}
      >
        <span style={{ fontSize: 96 }}>{s.emoji}</span>
      </div>
      <div className="flex justify-center gap-2 mt-7">
        {SLIDES.map((_, i) => (
          <div
            key={i}
            style={{
              width: i === slide ? 26 : 8,
              height: 8,
              borderRadius: 4,
              background: i === slide ? B : "#e2e8e4",
              transition: "all 0.3s",
            }}
          />
        ))}
      </div>
      <div className="px-8 mt-7">
        <h2 style={{ fontSize: 24, fontWeight: 900, color: DARK, lineHeight: 1.25, marginBottom: 12 }}>
          {s.title}
        </h2>
        <p style={{ color: "#6b7a72", fontSize: 15, lineHeight: 1.65 }}>{s.body}</p>
      </div>
      <div className="mt-auto px-6 pb-10">
        <button
          onClick={() => (isLast ? nav("login") : setSlide((v) => v + 1))}
          className="w-full flex items-center justify-center gap-2"
          style={{ background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16 }}
        >
          {isLast ? "Get Started" : "Next"}
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  );
}

// ─── LOGIN ────────────────────────────────────────────────────────────────────
function LoginScreen({ nav }: { nav: (s: Screen) => void }) {
  const [phone, setPhone] = useState("");
  const [pass, setPass] = useState("");
  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="flex-1 overflow-y-auto px-6">
        <div className="flex justify-center mt-5 mb-7">
          <div style={{ width: 64, height: 64, background: B, borderRadius: 20, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ticket size={30} color="white" strokeWidth={2} />
          </div>
        </div>
        <h1 style={{ fontSize: 30, fontWeight: 900, color: DARK, marginBottom: 4 }}>Welcome back</h1>
        <p style={{ color: "#6b7a72", fontSize: 14, marginBottom: 28 }}>Sign in to your Ekaadh account</p>
        <div className="flex flex-col gap-4">
          <div>
            <label style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", textTransform: "uppercase", letterSpacing: 1, display: "block", marginBottom: 6 }}>Phone Number</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+252 61 234 5678"
              style={{ width: "100%", background: "#f5f8f6", borderRadius: 18, padding: "16px 18px", border: "none", outline: "none", fontSize: 15, fontWeight: 500, color: DARK, boxSizing: "border-box" }}
            />
          </div>
          <div>
            <label style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", textTransform: "uppercase", letterSpacing: 1, display: "block", marginBottom: 6 }}>Password</label>
            <input
              type="password"
              value={pass}
              onChange={(e) => setPass(e.target.value)}
              placeholder="••••••••"
              style={{ width: "100%", background: "#f5f8f6", borderRadius: 18, padding: "16px 18px", border: "none", outline: "none", fontSize: 15, fontWeight: 500, color: DARK, boxSizing: "border-box" }}
            />
          </div>
        </div>
        <div className="text-right mt-2">
          <button style={{ fontSize: 13, fontWeight: 700, color: B }}>Forgot password?</button>
        </div>
        <button
          onClick={() => nav("home")}
          style={{ width: "100%", background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16, marginTop: 22, display: "block" }}
        >
          Sign In
        </button>
        <div className="flex items-center gap-3 my-6">
          <div className="flex-1 h-px bg-gray-100" />
          <span style={{ color: "#b8bfbb", fontSize: 13 }}>or</span>
          <div className="flex-1 h-px bg-gray-100" />
        </div>
        <button
          onClick={() => nav("register")}
          style={{ width: "100%", borderRadius: 20, padding: "16px 0", fontWeight: 800, fontSize: 15, border: `2px solid ${B}`, color: B, background: "transparent", display: "block" }}
        >
          Create Account
        </button>
      </div>
      <div className="pb-8 pt-4 flex justify-center">
        <button onClick={() => nav("staff-login")} style={{ fontSize: 13, fontWeight: 700, color: "#9ca3af", textDecoration: "underline" }}>
          Staff Login →
        </button>
      </div>
    </div>
  );
}

// ─── REGISTER ─────────────────────────────────────────────────────────────────
function RegisterScreen({ nav }: { nav: (s: Screen) => void }) {
  const [vals, setVals] = useState({ name: "", phone: "", pass: "", confirm: "" });
  const fields = [
    { key: "name" as const, label: "Full Name", type: "text", ph: "Amina Hassan" },
    { key: "phone" as const, label: "Phone Number", type: "tel", ph: "+252 61 234 5678" },
    { key: "pass" as const, label: "Password", type: "password", ph: "Min. 8 characters" },
    { key: "confirm" as const, label: "Confirm Password", type: "password", ph: "Re-enter password" },
  ];
  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="flex-1 overflow-y-auto px-6 pb-8">
        <button onClick={() => nav("login")} className="flex items-center gap-1 mb-5">
          <ChevronLeft size={20} color="#9ca3af" />
          <span style={{ fontSize: 14, fontWeight: 700, color: "#9ca3af" }}>Back</span>
        </button>
        <h1 style={{ fontSize: 30, fontWeight: 900, color: DARK, marginBottom: 4 }}>Create account</h1>
        <p style={{ color: "#6b7a72", fontSize: 14, marginBottom: 28 }}>Join Ekaadh and start discovering events</p>
        <div className="flex flex-col gap-4">
          {fields.map(({ key, label, type, ph }) => (
            <div key={key}>
              <label style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", textTransform: "uppercase", letterSpacing: 1, display: "block", marginBottom: 6 }}>{label}</label>
              <input
                type={type}
                value={vals[key]}
                onChange={(e) => setVals((v) => ({ ...v, [key]: e.target.value }))}
                placeholder={ph}
                style={{ width: "100%", background: "#f5f8f6", borderRadius: 18, padding: "16px 18px", border: "none", outline: "none", fontSize: 15, fontWeight: 500, color: DARK, boxSizing: "border-box" }}
              />
            </div>
          ))}
        </div>
        <button
          onClick={() => nav("home")}
          style={{ width: "100%", background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16, marginTop: 28, display: "block" }}
        >
          Create Account
        </button>
        <p style={{ textAlign: "center", fontSize: 14, color: "#6b7a72", marginTop: 16 }}>
          Already have an account?{" "}
          <button onClick={() => nav("login")} style={{ fontWeight: 800, color: B }}>Sign In</button>
        </p>
        <p style={{ textAlign: "center", fontSize: 11, color: "#b8bfbb", marginTop: 12, lineHeight: 1.6 }}>
          By creating an account you agree to our{" "}
          <span style={{ textDecoration: "underline" }}>Terms of Service</span> and{" "}
          <span style={{ textDecoration: "underline" }}>Privacy Policy</span>
        </p>
      </div>
    </div>
  );
}

// ─── HOME ────────────────────────────────────────────────────────────────────
function HomeScreen({ nav, setEvt }: { nav: (s: Screen) => void; setEvt: (id: string) => void }) {
  const [cat, setCat] = useState("All");
  const filtered = cat === "All" ? EVENTS : EVENTS.filter((e) => e.category === cat);
  return (
    <div className="flex flex-col h-full" style={{ background: "#f5f8f6" }}>
      <div className="bg-white">
        <StatusBar />
        <div className="px-5 pb-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <div className="flex items-center gap-1" style={{ color: "#6b7a72", fontSize: 12, fontWeight: 600 }}>
                <MapPin size={11} color={B} />
                <span>Mogadishu, Somalia</span>
              </div>
              <h1 style={{ fontSize: 20, fontWeight: 900, color: DARK, marginTop: 2 }}>Find Events Near You</h1>
            </div>
            <button className="relative" style={{ width: 42, height: 42, background: "#f5f8f6", borderRadius: 14, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Bell size={18} color={DARK} />
              <div style={{ position: "absolute", top: 9, right: 10, width: 7, height: 7, borderRadius: "50%", background: B, border: "1.5px solid white" }} />
            </button>
          </div>
          <div className="flex items-center gap-3" style={{ background: "#f5f8f6", borderRadius: 18, padding: "12px 16px" }}>
            <Search size={17} color="#b8bfbb" />
            <button onClick={() => nav("search")} style={{ flex: 1, textAlign: "left", fontSize: 14, color: "#b8bfbb", fontWeight: 500 }}>
              Search events, venues...
            </button>
            <div style={{ width: 28, height: 28, background: B, borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Star size={12} color="white" fill="white" />
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Category chips */}
        <div className="flex gap-2 px-5 py-4 overflow-x-auto" style={{ scrollbarWidth: "none" }}>
          {CATS.map((c) => (
            <button
              key={c}
              onClick={() => setCat(c)}
              style={{
                flexShrink: 0,
                padding: "8px 18px",
                borderRadius: 999,
                fontSize: 13,
                fontWeight: 700,
                background: cat === c ? B : "white",
                color: cat === c ? "white" : "#6b7a72",
                transition: "all 0.2s",
              }}
            >
              {c}
            </button>
          ))}
        </div>

        {/* Featured carousel */}
        <div className="px-5 mb-1">
          <div className="flex items-center justify-between mb-3">
            <span style={{ fontSize: 15, fontWeight: 900, color: DARK }}>Featured</span>
            <button style={{ fontSize: 12, fontWeight: 700, color: B }}>See all</button>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-1" style={{ scrollbarWidth: "none" }}>
            {EVENTS.slice(0, 4).map((ev) => (
              <button
                key={ev.id}
                onClick={() => { setEvt(ev.id); nav("event-detail"); }}
                style={{ position: "relative", flexShrink: 0, width: 224, height: 150, borderRadius: 20, overflow: "hidden", display: "block" }}
              >
                <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.72) 0%, rgba(0,0,0,0.1) 55%, transparent 100%)" }} />
                <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, padding: "0 14px 12px" }}>
                  <div style={{ color: "rgba(255,255,255,0.7)", fontSize: 10, fontWeight: 600 }}>{ev.date}</div>
                  <div style={{ color: "white", fontWeight: 800, fontSize: 13, lineHeight: 1.3 }}>{ev.title}</div>
                </div>
                <div style={{ position: "absolute", top: 10, right: 10, background: B, borderRadius: 999, padding: "2px 9px", fontSize: 10, fontWeight: 800, color: "white" }}>
                  {ev.category}
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Upcoming events */}
        <div className="px-5 mt-5 pb-28">
          <div className="flex items-center justify-between mb-3">
            <span style={{ fontSize: 15, fontWeight: 900, color: DARK }}>Upcoming Events</span>
            <button style={{ fontSize: 12, fontWeight: 700, color: B }}>See all</button>
          </div>
          {filtered.map((ev) => (
            <button
              key={ev.id}
              onClick={() => { setEvt(ev.id); nav("event-detail"); }}
              style={{ width: "100%", background: "white", borderRadius: 20, overflow: "hidden", marginBottom: 14, display: "block", textAlign: "left", boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}
            >
              <div style={{ position: "relative", height: 170, background: "#e2e8e4" }}>
                <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                <div style={{ position: "absolute", top: 12, left: 12, background: "white", borderRadius: 14, padding: "6px 10px", textAlign: "center", boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
                  <div style={{ fontSize: 9, fontWeight: 800, color: B, textTransform: "uppercase", letterSpacing: 0.5 }}>{ev.dm.m}</div>
                  <div style={{ fontSize: 18, fontWeight: 900, color: DARK, lineHeight: 1 }}>{ev.dm.d}</div>
                </div>
                <div style={{ position: "absolute", top: 12, right: 12, background: B, borderRadius: 999, padding: "3px 10px", fontSize: 10, fontWeight: 800, color: "white" }}>
                  {ev.category}
                </div>
              </div>
              <div style={{ padding: "14px 16px" }}>
                <div style={{ fontWeight: 900, fontSize: 14, color: DARK, marginBottom: 4, lineHeight: 1.3 }}>{ev.title}</div>
                <div className="flex items-center gap-1" style={{ color: "#b8bfbb", fontSize: 12, marginBottom: 10 }}>
                  <MapPin size={11} />
                  <span className="truncate">{ev.venue}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span style={{ fontSize: 12, color: "#b8bfbb" }}>{ev.time}</span>
                  <span style={{ fontSize: 14, fontWeight: 800, color: B }}>From ${ev.price}</span>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      <BottomNav active="home" nav={nav} />
    </div>
  );
}

// ─── SEARCH ───────────────────────────────────────────────────────────────────
function SearchScreen({ nav, setEvt }: { nav: (s: Screen) => void; setEvt: (id: string) => void }) {
  const [q, setQ] = useState("");
  const results = q ? EVENTS.filter((e) => e.title.toLowerCase().includes(q.toLowerCase())) : EVENTS;
  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="px-5 pb-3">
        <h1 style={{ fontSize: 26, fontWeight: 900, color: DARK, marginBottom: 14 }}>Search</h1>
        <div className="flex items-center gap-3" style={{ border: "1.5px solid #e8ede9", borderRadius: 18, padding: "12px 16px" }}>
          <Search size={17} color="#b8bfbb" />
          <input
            autoFocus
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Events, artists, venues..."
            style={{ flex: 1, border: "none", outline: "none", fontSize: 14, color: DARK, background: "transparent", fontFamily: "inherit" }}
          />
          {q && <button onClick={() => setQ("")}><X size={16} color="#b8bfbb" /></button>}
        </div>
      </div>
      <div className="flex-1 overflow-y-auto px-5 pb-28">
        <p style={{ fontSize: 11, fontWeight: 800, color: "#b8bfbb", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>
          {q ? `${results.length} result${results.length !== 1 ? "s" : ""}` : "Trending"}
        </p>
        {results.map((ev) => (
          <button
            key={ev.id}
            onClick={() => { setEvt(ev.id); nav("event-detail"); }}
            className="flex items-center gap-3 w-full text-left"
            style={{ paddingBottom: 14, marginBottom: 14, borderBottom: "1px solid #f5f8f6" }}
          >
            <div style={{ width: 56, height: 56, borderRadius: 14, overflow: "hidden", background: "#e2e8e4", flexShrink: 0 }}>
              <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 800, fontSize: 14, color: DARK, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{ev.title}</div>
              <div style={{ fontSize: 12, color: "#b8bfbb", marginTop: 2 }}>{ev.date} · {ev.category}</div>
            </div>
            <span style={{ fontSize: 13, fontWeight: 800, color: B, flexShrink: 0 }}>${ev.price}</span>
          </button>
        ))}
      </div>
      <BottomNav active="search" nav={nav} />
    </div>
  );
}

// ─── EVENT DETAIL ─────────────────────────────────────────────────────────────
function EventDetailScreen({ ev, nav }: { ev: (typeof EVENTS)[0]; nav: (s: Screen) => void }) {
  return (
    <div className="flex flex-col h-full bg-white">
      <div style={{ position: "relative", height: 280, flexShrink: 0, background: "#c8d8cf" }}>
        <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom, rgba(0,0,0,0.35) 0%, transparent 60%)" }} />
        <div style={{ position: "absolute", top: 0, left: 0, right: 0 }}>
          <StatusBar light />
          <div className="flex items-center justify-between px-5">
            <button
              onClick={() => nav("home")}
              style={{ width: 40, height: 40, borderRadius: 14, background: "rgba(0,0,0,0.28)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center" }}
            >
              <ChevronLeft size={20} color="white" />
            </button>
            <button style={{ width: 40, height: 40, borderRadius: 14, background: "rgba(0,0,0,0.28)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Star size={18} color="white" />
            </button>
          </div>
        </div>
        <div style={{ position: "absolute", bottom: 14, left: 18, background: B, borderRadius: 999, padding: "4px 12px", fontSize: 11, fontWeight: 800, color: "white" }}>
          {ev.category}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto" style={{ paddingBottom: 110 }}>
        <div className="px-5 pt-5">
          <h1 style={{ fontSize: 22, fontWeight: 900, color: DARK, lineHeight: 1.25, marginBottom: 16 }}>{ev.title}</h1>
          <div className="flex flex-col gap-3 mb-5">
            {[
              { icon: Clock, label: "Date & Time", val: `${ev.date} at ${ev.time}` },
              { icon: MapPin, label: "Venue", val: ev.venue },
            ].map(({ icon: Icon, label, val }) => (
              <div key={label} className="flex items-center gap-3">
                <div style={{ width: 36, height: 36, borderRadius: 12, background: BL, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Icon size={15} color={B} />
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "#b8bfbb", fontWeight: 600 }}>{label}</div>
                  <div style={{ fontSize: 14, fontWeight: 800, color: DARK }}>{val}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Map preview */}
          <div style={{ borderRadius: 18, overflow: "hidden", height: 96, background: "#ddeee5", marginBottom: 18 }}>
            <svg width="100%" height="96" viewBox="0 0 340 96" preserveAspectRatio="xMidYMid slice">
              <rect width="340" height="96" fill="#ddeee5" />
              <line x1="0" y1="48" x2="340" y2="48" stroke="#c0d8cb" strokeWidth="9" />
              <line x1="170" y1="0" x2="170" y2="96" stroke="#c0d8cb" strokeWidth="9" />
              <line x1="0" y1="24" x2="340" y2="24" stroke="#cfe4d9" strokeWidth="4" />
              <line x1="0" y1="72" x2="340" y2="72" stroke="#cfe4d9" strokeWidth="4" />
              <line x1="85" y1="0" x2="85" y2="96" stroke="#cfe4d9" strokeWidth="4" />
              <line x1="255" y1="0" x2="255" y2="96" stroke="#cfe4d9" strokeWidth="4" />
              <rect x="10" y="8" width="64" height="30" rx="5" fill="#c0d8cb" opacity="0.6" />
              <rect x="10" y="54" width="64" height="32" rx="5" fill="#c0d8cb" opacity="0.6" />
              <rect x="90" y="8" width="68" height="30" rx="5" fill="#c0d8cb" opacity="0.6" />
              <rect x="182" y="54" width="64" height="32" rx="5" fill="#c0d8cb" opacity="0.6" />
              <rect x="262" y="8" width="66" height="30" rx="5" fill="#c0d8cb" opacity="0.6" />
              <circle cx="170" cy="48" r="16" fill={B} />
              <circle cx="170" cy="48" r="9" fill="white" />
              <circle cx="170" cy="48" r="4" fill={B} />
            </svg>
          </div>

          <h3 style={{ fontSize: 14, fontWeight: 900, color: DARK, marginBottom: 8 }}>About this event</h3>
          <p style={{ color: "#6b7a72", fontSize: 14, lineHeight: 1.7, whiteSpace: "pre-line" }}>{ev.description}</p>
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "white", borderTop: "1px solid #f0f4f2", padding: "16px 20px 28px", display: "flex", alignItems: "center", gap: 16 }}>
        <div>
          <div style={{ fontSize: 11, color: "#b8bfbb", fontWeight: 600 }}>Starting from</div>
          <div style={{ fontSize: 26, fontWeight: 900, color: B }}>${ev.price}</div>
        </div>
        <button
          onClick={() => nav("ticket-selection")}
          style={{ flex: 1, background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16 }}
        >
          Get Tickets
        </button>
      </div>
    </div>
  );
}

// ─── TICKET SELECTION ─────────────────────────────────────────────────────────
function TicketSelectionScreen({ ev, nav }: { ev: (typeof EVENTS)[0]; nav: (s: Screen) => void }) {
  const [ga, setGa] = useState(0);
  const [vip, setVip] = useState(0);
  const gaP = ev.price;
  const vipP = ev.price * 3;
  const total = ga * gaP + vip * vipP;
  const qty = ga + vip;

  const Stepper = ({ val, set, price, label, desc }: { val: number; set: (v: number) => void; price: number; label: string; desc: string }) => (
    <div style={{ borderRadius: 20, padding: 16, border: `2px solid ${val > 0 ? B : "#f0f4f2"}`, transition: "border-color 0.2s" }}>
      <div className="flex items-start justify-between mb-4">
        <div>
          <div style={{ fontWeight: 900, fontSize: 15, color: DARK }}>{label}</div>
          <div style={{ fontSize: 12, color: "#b8bfbb", marginTop: 2 }}>{desc}</div>
        </div>
        <div style={{ fontWeight: 900, fontSize: 17, color: B }}>${price}</div>
      </div>
      <div className="flex items-center gap-4">
        <button
          onClick={() => set(Math.max(0, val - 1))}
          style={{ width: 38, height: 38, borderRadius: 999, border: `2px solid ${val > 0 ? B : "#e8ede9"}`, display: "flex", alignItems: "center", justifyContent: "center" }}
        >
          <Minus size={14} color={val > 0 ? B : "#b8bfbb"} />
        </button>
        <span style={{ fontWeight: 900, fontSize: 22, color: DARK, minWidth: 24, textAlign: "center" }}>{val}</span>
        <button
          onClick={() => set(val + 1)}
          style={{ width: 38, height: 38, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}
        >
          <Plus size={14} color="white" />
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="flex items-center gap-3 px-5 pb-3 border-b border-gray-50">
        <button onClick={() => nav("event-detail")}><ChevronLeft size={22} color={DARK} /></button>
        <span style={{ fontWeight: 900, fontSize: 18, color: DARK }}>Select Tickets</span>
      </div>
      <div className="flex-1 overflow-y-auto px-5" style={{ paddingBottom: 100 }}>
        <div className="flex items-center gap-3 py-4 mb-2" style={{ borderBottom: "1px solid #f5f8f6" }}>
          <div style={{ width: 60, height: 60, borderRadius: 16, overflow: "hidden", background: "#e2e8e4", flexShrink: 0 }}>
            <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          </div>
          <div>
            <div style={{ fontWeight: 900, fontSize: 14, color: DARK }}>{ev.title}</div>
            <div style={{ fontSize: 12, color: "#b8bfbb", marginTop: 2 }}>{ev.date} · {ev.time}</div>
          </div>
        </div>
        <div className="flex flex-col gap-3 mt-4">
          <Stepper val={ga} set={setGa} price={gaP} label="General Admission" desc="Access to all general areas" />
          <Stepper val={vip} set={setVip} price={vipP} label="VIP Experience" desc="Priority entry + lounge access" />
        </div>
        {total > 0 && (
          <div style={{ background: BL, borderRadius: 18, padding: "16px 18px", marginTop: 18, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: "#6b7a72" }}>{qty} ticket{qty !== 1 ? "s" : ""} selected</span>
            <span style={{ fontWeight: 900, fontSize: 22, color: B }}>${total}</span>
          </div>
        )}
      </div>
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "white", borderTop: "1px solid #f0f4f2", padding: "16px 20px 28px" }}>
        <button
          onClick={() => total > 0 && nav("checkout")}
          style={{ width: "100%", background: total > 0 ? B : "#e2e8e4", borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16, opacity: total > 0 ? 1 : 0.7 }}
        >
          {total > 0 ? `Proceed to Checkout · $${total}` : "Select at least 1 ticket"}
        </button>
      </div>
    </div>
  );
}

// ─── CHECKOUT ─────────────────────────────────────────────────────────────────
function CheckoutScreen({ ev, nav }: { ev: (typeof EVENTS)[0]; nav: (s: Screen) => void }) {
  const [pay, setPay] = useState<"zaad" | "edahab" | null>(null);
  const [vals, setVals] = useState({ name: "", email: "", phone: "" });
  const subtotal = ev.price * 2 + 1;

  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="flex items-center gap-3 px-5 pb-3 border-b border-gray-50">
        <button onClick={() => nav("ticket-selection")}><ChevronLeft size={22} color={DARK} /></button>
        <span style={{ fontWeight: 900, fontSize: 18, color: DARK }}>Checkout</span>
      </div>
      <div className="flex-1 overflow-y-auto px-5" style={{ paddingBottom: 110 }}>
        {/* Buyer info */}
        <div className="mt-5">
          <p style={{ fontSize: 11, fontWeight: 800, color: "#b8bfbb", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>Your Details</p>
          <div className="flex flex-col gap-3">
            {[
              { k: "name" as const, label: "Full Name", type: "text", ph: "Amina Hassan" },
              { k: "email" as const, label: "Email", type: "email", ph: "amina@example.com" },
              { k: "phone" as const, label: "Phone", type: "tel", ph: "+252 61 234 5678" },
            ].map(({ k, label, type, ph }) => (
              <div key={k}>
                <label style={{ fontSize: 12, fontWeight: 700, color: "#6b7a72", display: "block", marginBottom: 6 }}>{label}</label>
                <input
                  type={type}
                  value={vals[k]}
                  onChange={(e) => setVals((v) => ({ ...v, [k]: e.target.value }))}
                  placeholder={ph}
                  style={{ width: "100%", background: "#f5f8f6", borderRadius: 16, padding: "14px 16px", border: "none", outline: "none", fontSize: 14, fontWeight: 500, color: DARK, boxSizing: "border-box", fontFamily: "inherit" }}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Payment method */}
        <div className="mt-6">
          <p style={{ fontSize: 11, fontWeight: 800, color: "#b8bfbb", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>Payment Method</p>
          <div className="flex gap-3">
            {[
              { id: "zaad" as const, name: "Zaad", sub: "Telesom", abbr: "Z", bg: "#fff3e0", clr: "#e65100" },
              { id: "edahab" as const, name: "eDahab", sub: "Hormuud", abbr: "eD", bg: "#e3f2fd", clr: "#1565c0" },
            ].map(({ id, name, sub, abbr, bg, clr }) => (
              <button
                key={id}
                onClick={() => setPay(id)}
                style={{ flex: 1, position: "relative", borderRadius: 18, padding: "16px 12px", border: `2px solid ${pay === id ? B : "#f0f4f2"}`, display: "flex", flexDirection: "column", alignItems: "center", gap: 8, transition: "border-color 0.2s" }}
              >
                <div style={{ width: 48, height: 48, borderRadius: 14, background: bg, display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <span style={{ fontWeight: 900, fontSize: 15, color: clr }}>{abbr}</span>
                </div>
                <div>
                  <div style={{ fontWeight: 900, fontSize: 14, color: DARK, textAlign: "center" }}>{name}</div>
                  <div style={{ fontSize: 11, color: "#b8bfbb", textAlign: "center" }}>{sub}</div>
                </div>
                {pay === id && (
                  <div style={{ position: "absolute", top: 10, right: 10, width: 20, height: 20, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <Check size={11} color="white" strokeWidth={3} />
                  </div>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Order summary */}
        <div style={{ background: "#f5f8f6", borderRadius: 18, padding: "16px 18px", marginTop: 20 }}>
          <p style={{ fontSize: 11, fontWeight: 800, color: "#b8bfbb", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>Order Summary</p>
          {[
            { label: "2× General Admission", val: `$${ev.price * 2}` },
            { label: "Service fee", val: "$1" },
          ].map(({ label, val }) => (
            <div key={label} className="flex justify-between items-center mb-2">
              <span style={{ fontSize: 13, color: "#6b7a72" }}>{label}</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: DARK }}>{val}</span>
            </div>
          ))}
          <div className="flex justify-between items-center pt-3" style={{ borderTop: "1px solid #e8ede9" }}>
            <span style={{ fontSize: 15, fontWeight: 900, color: DARK }}>Total</span>
            <span style={{ fontSize: 18, fontWeight: 900, color: B }}>${subtotal}</span>
          </div>
        </div>

        {/* Simulate failed */}
        <button onClick={() => nav("checkout-failed")} style={{ width: "100%", marginTop: 14, fontSize: 12, color: "#b8bfbb", textAlign: "center" }}>
          Simulate failed payment →
        </button>
      </div>

      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "white", borderTop: "1px solid #f0f4f2", padding: "16px 20px 28px" }}>
        <button
          onClick={() => nav("checkout-processing")}
          style={{ width: "100%", background: pay ? B : "#e2e8e4", borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16 }}
        >
          Pay Now · ${subtotal}
        </button>
      </div>
    </div>
  );
}

// ─── PROCESSING ───────────────────────────────────────────────────────────────
function ProcessingScreen({ nav }: { nav: (s: Screen) => void }) {
  useEffect(() => {
    const t = setTimeout(() => nav("order-confirmation"), 2600);
    return () => clearTimeout(t);
  }, [nav]);
  return (
    <div className="flex flex-col h-full items-center justify-center" style={{ background: BL }}>
      <StatusBar />
      <div className="flex-1 flex flex-col items-center justify-center gap-7">
        <div style={{ width: 100, height: 100, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Loader2 size={46} color="white" className="animate-spin" />
        </div>
        <div style={{ textAlign: "center" }}>
          <h2 style={{ fontSize: 22, fontWeight: 900, color: DARK }}>Processing Payment</h2>
          <p style={{ color: "#6b7a72", fontSize: 14, marginTop: 6 }}>Please wait, do not close the app…</p>
        </div>
        <div className="flex gap-1.5">
          {[0, 1, 2].map((i) => (
            <div key={i} style={{ width: 8, height: 8, borderRadius: 999, background: B, opacity: 0.3 + i * 0.35, animation: `pulse ${0.6 + i * 0.2}s ease-in-out infinite alternate` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── PAYMENT FAILED ───────────────────────────────────────────────────────────
function PaymentFailedScreen({ nav }: { nav: (s: Screen) => void }) {
  return (
    <div className="flex flex-col h-full" style={{ background: "#fff5f5" }}>
      <StatusBar />
      <div className="flex-1 flex flex-col items-center justify-center gap-6 px-8">
        <div style={{ width: 100, height: 100, borderRadius: 999, background: "#fee2e2", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <XCircle size={56} color="#ef4444" />
        </div>
        <div style={{ textAlign: "center" }}>
          <h2 style={{ fontSize: 26, fontWeight: 900, color: DARK, marginBottom: 10 }}>Payment Failed</h2>
          <p style={{ color: "#6b7a72", fontSize: 15, lineHeight: 1.65 }}>
            We could not process your payment. Please check your mobile wallet balance or try a different method.
          </p>
        </div>
        <button
          onClick={() => nav("checkout")}
          style={{ width: "100%", background: "#ef4444", borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16 }}
        >
          Try Again
        </button>
        <button onClick={() => nav("home")} style={{ fontSize: 14, fontWeight: 700, color: "#b8bfbb" }}>
          Back to Home
        </button>
      </div>
    </div>
  );
}

// ─── ORDER CONFIRMATION ────────────────────────────────────────────────────────
function OrderConfirmationScreen({ ev, nav }: { ev: (typeof EVENTS)[0]; nav: (s: Screen) => void }) {
  const tickets = [
    { id: "EKD-7412", name: "Amina Hassan", type: "General Admission" },
    { id: "EKD-7413", name: "Mohamed Ali", type: "General Admission" },
  ];
  return (
    <div className="flex flex-col h-full" style={{ background: "#f5f8f6" }}>
      <div style={{ background: "white" }}>
        <StatusBar />
        <div className="flex flex-col items-center" style={{ paddingBottom: 24, paddingTop: 8 }}>
          <div style={{ width: 80, height: 80, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>
            <Check size={40} color="white" strokeWidth={3} />
          </div>
          <h1 style={{ fontSize: 24, fontWeight: 900, color: DARK }}>Payment Successful!</h1>
          <p style={{ fontSize: 13, color: "#b8bfbb", marginTop: 4 }}>Order #EKD-{String(Date.now()).slice(-6)}</p>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pt-4" style={{ paddingBottom: 100 }}>
        {/* Event card */}
        <div style={{ background: "white", borderRadius: 18, padding: 14, marginBottom: 16, display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 56, height: 56, borderRadius: 14, overflow: "hidden", background: "#e2e8e4", flexShrink: 0 }}>
            <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          </div>
          <div>
            <div style={{ fontWeight: 900, fontSize: 14, color: DARK }}>{ev.title}</div>
            <div style={{ fontSize: 12, color: "#b8bfbb", marginTop: 2 }}>{ev.date} · {ev.time}</div>
            <div style={{ fontSize: 12, color: "#b8bfbb" }}>{ev.venue}</div>
          </div>
        </div>

        <p style={{ fontSize: 11, fontWeight: 800, color: "#b8bfbb", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>Your Tickets</p>

        {tickets.map((t) => (
          <div key={t.id} style={{ background: "white", borderRadius: 20, overflow: "hidden", marginBottom: 14, boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}>
            <div style={{ padding: "16px 18px 12px" }}>
              <div className="flex justify-between items-start">
                <div>
                  <div style={{ fontWeight: 900, fontSize: 15, color: DARK }}>{t.name}</div>
                  <div style={{ fontSize: 12, color: "#b8bfbb", marginTop: 2 }}>{t.type}</div>
                  <div style={{ fontSize: 12, fontWeight: 800, color: B, marginTop: 4, fontFamily: "monospace", letterSpacing: 0.5 }}>{t.id}</div>
                </div>
                <div style={{ background: BL, borderRadius: 999, padding: "4px 12px", fontSize: 11, fontWeight: 800, color: B }}>
                  Valid
                </div>
              </div>
            </div>
            <div className="flex items-center px-3">
              <div style={{ width: 22, height: 22, borderRadius: 999, background: "#f5f8f6" }} />
              <div style={{ flex: 1, borderTop: "2px dashed #e8ede9", margin: "0 4px" }} />
              <div style={{ width: 22, height: 22, borderRadius: 999, background: "#f5f8f6" }} />
            </div>
            <div className="flex justify-center" style={{ padding: "16px 0" }}>
              <QRCodeSVG size={130} />
            </div>
            <div style={{ textAlign: "center", paddingBottom: 14, fontSize: 11, color: "#b8bfbb" }}>
              Show QR at entry · {ev.date}
            </div>
          </div>
        ))}

        {/* Delivery notice */}
        <div style={{ background: BL, borderRadius: 18, padding: "14px 16px", display: "flex", gap: 12, alignItems: "flex-start" }}>
          <div style={{ width: 24, height: 24, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, marginTop: 1 }}>
            <Check size={12} color="white" strokeWidth={3} />
          </div>
          <p style={{ fontSize: 13, color: "#6b7a72", lineHeight: 1.6 }}>
            Tickets also sent via{" "}
            <strong style={{ color: DARK }}>WhatsApp, Email & SMS</strong> to your registered contact details.
          </p>
        </div>
      </div>

      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "white", borderTop: "1px solid #f0f4f2", padding: "16px 20px 28px" }}>
        <button
          onClick={() => nav("my-tickets")}
          style={{ width: "100%", background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16 }}
        >
          View My Tickets
        </button>
      </div>
    </div>
  );
}

// ─── MY TICKETS ───────────────────────────────────────────────────────────────
function MyTicketsScreen({ nav }: { nav: (s: Screen) => void }) {
  const [tab, setTab] = useState<"upcoming" | "past">("upcoming");
  const upcoming = [
    { id: "EKD-7412", title: "Mogadishu Music Festival", date: "Jul 19, 2026", time: "6:00 PM", venue: "Lido Beach Arena", type: "General Admission", img: EVENTS[0].image, valid: true },
    { id: "EKD-003", title: "TEDx Mogadishu 2026", date: "Aug 2, 2026", time: "9:00 AM", venue: "SYL Hotel", type: "VIP Experience", img: EVENTS[1].image, valid: true },
  ];
  const past = [
    { id: "EKD-P01", title: "Hargeisa Cultural Night", date: "Jun 10, 2026", time: "7:00 PM", venue: "Cultural Center", type: "General Admission", img: EVENTS[3].image, valid: false },
  ];
  const tickets = tab === "upcoming" ? upcoming : past;

  return (
    <div className="flex flex-col h-full bg-white">
      <StatusBar />
      <div className="px-5 pb-4">
        <h1 style={{ fontSize: 26, fontWeight: 900, color: DARK, marginBottom: 14 }}>My Tickets</h1>
        <div style={{ display: "flex", gap: 4, padding: 4, background: "#f5f8f6", borderRadius: 18 }}>
          {(["upcoming", "past"] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              style={{
                flex: 1,
                padding: "10px 0",
                borderRadius: 14,
                fontSize: 13,
                fontWeight: 800,
                background: tab === t ? B : "transparent",
                color: tab === t ? "white" : "#b8bfbb",
                transition: "all 0.2s",
              }}
            >
              {t === "upcoming" ? "Upcoming" : "Past"}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-28">
        {tickets.map((tk) => (
          <button
            key={tk.id}
            onClick={() => nav("ticket-view")}
            style={{ width: "100%", background: "white", borderRadius: 20, overflow: "hidden", marginBottom: 14, border: "1px solid #f0f4f2", textAlign: "left", display: "block", boxShadow: "0 2px 10px rgba(0,0,0,0.05)" }}
          >
            <div style={{ position: "relative", height: 120, background: "#e2e8e4" }}>
              <img src={tk.img} alt={tk.title} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
              <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.38)" }} />
              <div style={{ position: "absolute", bottom: 12, left: 16, right: 16 }}>
                <div style={{ color: "white", fontWeight: 900, fontSize: 14 }}>{tk.title}</div>
                <div style={{ color: "rgba(255,255,255,0.65)", fontSize: 11, marginTop: 2 }}>{tk.date} · {tk.time}</div>
              </div>
              <div style={{ position: "absolute", top: 12, right: 12, background: tk.valid ? B : "#9ca3af", borderRadius: 999, padding: "3px 10px", fontSize: 10, fontWeight: 800, color: "white" }}>
                {tk.valid ? "Valid" : "Used"}
              </div>
            </div>
            <div className="flex items-center justify-between px-4 py-3">
              <div>
                <div style={{ fontSize: 12, fontWeight: 600, color: "#6b7a72" }}>{tk.type}</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: B, fontFamily: "monospace", marginTop: 2, letterSpacing: 0.5 }}>{tk.id}</div>
              </div>
              <div className="flex items-center gap-1" style={{ color: B }}>
                <QrCode size={14} />
                <span style={{ fontSize: 12, fontWeight: 700 }}>View QR</span>
              </div>
            </div>
          </button>
        ))}
      </div>
      <BottomNav active="my-tickets" nav={nav} />
    </div>
  );
}

// ─── TICKET VIEW ──────────────────────────────────────────────────────────────
function TicketViewScreen({ nav }: { nav: (s: Screen) => void }) {
  return (
    <div className="flex flex-col h-full" style={{ background: BD }}>
      <StatusBar light />
      <div className="flex items-center gap-3 px-5 pb-4">
        <button onClick={() => nav("my-tickets")}><ChevronLeft size={22} color="white" /></button>
        <span style={{ fontWeight: 900, fontSize: 18, color: "white" }}>Your Ticket</span>
      </div>
      <div className="flex-1 overflow-y-auto px-5 pb-10">
        <div style={{ background: "white", borderRadius: 24, overflow: "hidden", boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
          {/* Hero */}
          <div style={{ position: "relative", height: 150, background: "#c8d8cf" }}>
            <img src={EVENTS[0].image} alt="Event" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom, rgba(0,0,0,0.2), rgba(0,0,0,0.6))" }} />
            <div style={{ position: "absolute", bottom: 14, left: 18, right: 18 }}>
              <div style={{ color: "white", fontWeight: 900, fontSize: 16, lineHeight: 1.3 }}>Mogadishu Music Festival</div>
              <div style={{ color: "rgba(255,255,255,0.7)", fontSize: 12, marginTop: 3 }}>Jul 19, 2026 · 6:00 PM · Lido Beach Arena</div>
            </div>
          </div>

          {/* Details */}
          <div style={{ padding: "18px 20px 14px" }}>
            <div className="flex justify-between items-start mb-4">
              <div>
                <div style={{ fontSize: 11, color: "#b8bfbb", fontWeight: 600 }}>Ticket Holder</div>
                <div style={{ fontSize: 18, fontWeight: 900, color: DARK }}>Amina Hassan</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 11, color: "#b8bfbb", fontWeight: 600 }}>Type</div>
                <div style={{ fontSize: 14, fontWeight: 900, color: DARK }}>General Admission</div>
              </div>
            </div>
            <div style={{ textAlign: "center", fontSize: 12, fontFamily: "monospace", fontWeight: 800, color: B, letterSpacing: 2 }}>
              EKD-7412 · ADMIT ONE
            </div>
          </div>

          {/* Perforation */}
          <div className="flex items-center px-3">
            <div style={{ width: 26, height: 26, borderRadius: 999, background: BD }} />
            <div style={{ flex: 1, borderTop: "2.5px dashed #e8ede9", margin: "0 5px" }} />
            <div style={{ width: 26, height: 26, borderRadius: 999, background: BD }} />
          </div>

          {/* QR Code */}
          <div className="flex flex-col items-center" style={{ padding: "24px 0 20px" }}>
            <QRCodeSVG size={210} />
            <p style={{ fontSize: 11, color: "#b8bfbb", marginTop: 12, fontWeight: 600 }}>Scan at entry · Valid once only</p>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3 mt-5">
          {[
            { icon: Share2, label: "Share" },
            { icon: Download, label: "Download" },
          ].map(({ icon: Icon, label }) => (
            <button
              key={label}
              style={{ flex: 1, background: "rgba(255,255,255,0.18)", borderRadius: 18, padding: "14px 0", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "white", fontWeight: 800, fontSize: 14 }}
            >
              <Icon size={16} />
              {label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── PROFILE ──────────────────────────────────────────────────────────────────
function ProfileScreen({ nav }: { nav: (s: Screen) => void }) {
  const items = [
    { label: "My Orders", icon: Ticket },
    { label: "Notifications", icon: Bell },
    { label: "Payment Methods", icon: Download },
    { label: "Help & Support", icon: MessageCircle },
    { label: "Privacy Policy", icon: Shield },
  ];
  return (
    <div className="flex flex-col h-full" style={{ background: "#f5f8f6" }}>
      <div style={{ background: "white" }}>
        <StatusBar />
        <div style={{ padding: "0 20px 24px" }}>
          <h1 style={{ fontSize: 26, fontWeight: 900, color: DARK, marginBottom: 16 }}>Profile</h1>
          <div className="flex items-center gap-4">
            <div style={{ width: 64, height: 64, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26, fontWeight: 900, color: "white" }}>
              A
            </div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 16, color: DARK }}>Amina Hassan</div>
              <div style={{ fontSize: 13, color: "#b8bfbb", marginTop: 2 }}>+252 61 234 5678</div>
              <div style={{ fontSize: 13, color: "#b8bfbb" }}>amina@example.com</div>
            </div>
          </div>
        </div>
      </div>
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-28">
        {items.map(({ label, icon: Icon }) => (
          <div key={label} style={{ background: "white", borderRadius: 18, padding: "14px 16px", display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
            <div className="flex items-center gap-3">
              <div style={{ width: 36, height: 36, borderRadius: 12, background: BL, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <Icon size={16} color={B} />
              </div>
              <span style={{ fontWeight: 700, fontSize: 14, color: DARK }}>{label}</span>
            </div>
            <ChevronRight size={16} color="#b8bfbb" />
          </div>
        ))}
        <button
          onClick={() => nav("login")}
          style={{ width: "100%", padding: "16px 0", borderRadius: 18, fontWeight: 800, fontSize: 15, border: "2px solid #fee2e2", color: "#ef4444", background: "transparent", marginTop: 8 }}
        >
          Sign Out
        </button>
      </div>
      <BottomNav active="profile" nav={nav} />
    </div>
  );
}

// ─── STAFF LOGIN ──────────────────────────────────────────────────────────────
function StaffLoginScreen({ nav }: { nav: (s: Screen) => void }) {
  const [phone, setPhone] = useState("");
  const [pass, setPass] = useState("");
  return (
    <div className="flex flex-col h-full" style={{ background: "#0a1410" }}>
      <StatusBar light />
      <div className="flex-1 overflow-y-auto px-6 pb-8">
        <button onClick={() => nav("login")} className="flex items-center gap-1 mb-8">
          <ChevronLeft size={18} color="rgba(255,255,255,0.4)" />
          <span style={{ fontSize: 14, fontWeight: 700, color: "rgba(255,255,255,0.4)" }}>Customer Login</span>
        </button>
        <div className="flex items-center gap-3 mb-6">
          <div style={{ width: 52, height: 52, borderRadius: 18, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <ShieldCheck size={26} color="white" />
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.35)", textTransform: "uppercase", letterSpacing: 2 }}>Staff Portal</div>
            <h1 style={{ fontSize: 26, fontWeight: 900, color: "white" }}>Staff Login</h1>
          </div>
        </div>
        <div style={{ background: "rgba(16,183,127,0.1)", borderRadius: 16, padding: "14px 16px", marginBottom: 28, border: "1px solid rgba(16,183,127,0.2)" }}>
          <p style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", lineHeight: 1.6 }}>
            This portal is for <strong style={{ color: "rgba(255,255,255,0.75)" }}>authorized event staff only</strong>. Contact your event supervisor for access credentials.
          </p>
        </div>
        <div className="flex flex-col gap-4">
          {[
            { label: "Staff Phone", val: phone, set: setPhone, type: "tel", ph: "+252 61 000 0000" },
            { label: "Password", val: pass, set: setPass, type: "password", ph: "••••••••" },
          ].map(({ label, val, set, type, ph }) => (
            <div key={label}>
              <label style={{ fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.35)", textTransform: "uppercase", letterSpacing: 1, display: "block", marginBottom: 6 }}>{label}</label>
              <input
                type={type}
                value={val}
                onChange={(e) => set(e.target.value)}
                placeholder={ph}
                style={{ width: "100%", background: "rgba(255,255,255,0.08)", borderRadius: 18, padding: "16px 18px", border: "1px solid rgba(255,255,255,0.08)", outline: "none", fontSize: 15, fontWeight: 500, color: "white", boxSizing: "border-box", fontFamily: "inherit" }}
              />
            </div>
          ))}
        </div>
        <button
          onClick={() => nav("staff-events")}
          style={{ width: "100%", background: B, borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16, marginTop: 28, display: "block" }}
        >
          Login as Staff
        </button>
        <p style={{ textAlign: "center", fontSize: 11, color: "rgba(255,255,255,0.2)", marginTop: 20, lineHeight: 1.6 }}>
          Unauthorized access is strictly prohibited and subject to legal action.
        </p>
      </div>
    </div>
  );
}

// ─── STAFF EVENT SELECT ───────────────────────────────────────────────────────
const STAFF_EVENTS = [
  { id: "s1", title: "Mogadishu Music Festival", date: "Jul 19, 2026", time: "6:00 PM", venue: "Lido Beach Arena", image: "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&h=450&fit=crop&auto=format", checked: 847, capacity: 5000 },
  { id: "s2", title: "TEDx Mogadishu 2026", date: "Aug 2, 2026", time: "9:00 AM", venue: "SYL Hotel Conference Centre", image: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=450&fit=crop&auto=format", checked: 214, capacity: 600 },
  { id: "s3", title: "Somali Premier League Finals", date: "Aug 15, 2026", time: "5:00 PM", venue: "Banadir Stadium", image: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&h=450&fit=crop&auto=format", checked: 0, capacity: 20000 },
];

function StaffEventSelectScreen({
  nav,
  setStaffEvent,
}: {
  nav: (s: Screen) => void;
  setStaffEvent: (id: string) => void;
}) {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <div className="flex flex-col h-full" style={{ background: "#0a1410" }}>
      <StatusBar light />
      <div style={{ padding: "0 20px 20px" }}>
        <button onClick={() => nav("staff-login")} className="flex items-center gap-1 mb-6">
          <ChevronLeft size={18} color="rgba(255,255,255,0.4)" />
          <span style={{ fontSize: 14, fontWeight: 700, color: "rgba(255,255,255,0.4)" }}>Staff Login</span>
        </button>
        <div className="flex items-center gap-3">
          <div style={{ width: 44, height: 44, borderRadius: 14, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Calendar size={22} color="white" />
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.3)", textTransform: "uppercase", letterSpacing: 2 }}>Step 1 of 2</div>
            <h1 style={{ fontSize: 22, fontWeight: 900, color: "white" }}>Select Your Event</h1>
          </div>
        </div>
        <p style={{ fontSize: 13, color: "rgba(255,255,255,0.4)", marginTop: 10, lineHeight: 1.6 }}>
          Choose the event you are checking guests into today.
        </p>
      </div>

      <div className="flex-1 overflow-y-auto px-5" style={{ paddingBottom: 110 }}>
        {STAFF_EVENTS.map((ev) => {
          const pct = Math.round((ev.checked / ev.capacity) * 100);
          const isSelected = selected === ev.id;
          return (
            <button
              key={ev.id}
              onClick={() => setSelected(ev.id)}
              style={{
                width: "100%",
                borderRadius: 20,
                overflow: "hidden",
                marginBottom: 14,
                border: `2px solid ${isSelected ? B : "rgba(255,255,255,0.07)"}`,
                background: isSelected ? "rgba(16,183,127,0.08)" : "rgba(255,255,255,0.04)",
                textAlign: "left",
                display: "block",
                transition: "border-color 0.2s, background 0.2s",
              }}
            >
              {/* Event image strip */}
              <div style={{ position: "relative", height: 110, background: "#1a2d25" }}>
                <img src={ev.image} alt={ev.title} style={{ width: "100%", height: "100%", objectFit: "cover", opacity: 0.55 }} />
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(10,20,16,0.85) 0%, transparent 60%)" }} />
                <div style={{ position: "absolute", bottom: 10, left: 14, right: 14 }}>
                  <div style={{ fontSize: 15, fontWeight: 900, color: "white", lineHeight: 1.3 }}>{ev.title}</div>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.55)", marginTop: 3 }}>{ev.date} · {ev.time}</div>
                </div>
                {isSelected && (
                  <div style={{ position: "absolute", top: 10, right: 10, width: 28, height: 28, borderRadius: 999, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <Check size={14} color="white" strokeWidth={3} />
                  </div>
                )}
              </div>

              {/* Stats */}
              <div style={{ padding: "12px 14px" }}>
                <div className="flex items-center gap-1 mb-8" style={{ color: "rgba(255,255,255,0.4)", fontSize: 12 }}>
                  <MapPin size={11} color={B} />
                  <span>{ev.venue}</span>
                </div>
                <div className="flex items-center justify-between mb-2">
                  <span style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.5)" }}>Check-ins</span>
                  <span style={{ fontSize: 13, fontWeight: 900, color: B }}>{ev.checked.toLocaleString()} / {ev.capacity.toLocaleString()}</span>
                </div>
                {/* Progress bar */}
                <div style={{ height: 5, background: "rgba(255,255,255,0.08)", borderRadius: 999 }}>
                  <div style={{ height: "100%", width: `${pct}%`, borderRadius: 999, background: pct > 80 ? "#f59e0b" : B, transition: "width 0.4s" }} />
                </div>
                <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginTop: 5, textAlign: "right" }}>{pct}% capacity</div>
              </div>
            </button>
          );
        })}
      </div>

      {/* CTA */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, padding: "16px 20px 28px", background: "#0a1410", borderTop: "1px solid rgba(255,255,255,0.06)" }}>
        <button
          onClick={() => {
            if (!selected) return;
            setStaffEvent(selected);
            nav("scanner");
          }}
          style={{
            width: "100%",
            background: selected ? B : "rgba(255,255,255,0.08)",
            borderRadius: 20,
            padding: "17px 0",
            color: selected ? "white" : "rgba(255,255,255,0.25)",
            fontWeight: 800,
            fontSize: 16,
            transition: "background 0.2s",
          }}
        >
          {selected ? "Start Scanning →" : "Select an event to continue"}
        </button>
      </div>
    </div>
  );
}

// ─── SCANNER ─────────────────────────────────────────────────────────────────
function ScannerScreen({ nav, staffEv }: { nav: (s: Screen) => void; staffEv: typeof STAFF_EVENTS[0] | null }) {
  const title = staffEv?.title ?? "Mogadishu Music Festival";
  const meta = staffEv ? `${staffEv.date} · ${staffEv.venue} · Gate A` : "Jul 19, 2026 · Lido Beach Arena · Gate A";
  return (
    <div className="flex flex-col h-full" style={{ background: "#080e0b" }}>
      <StatusBar light />
      <div style={{ padding: "0 20px 16px" }}>
        <button onClick={() => nav("staff-events")} className="flex items-center gap-1 mb-3">
          <ChevronLeft size={16} color="rgba(255,255,255,0.35)" />
          <span style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.35)" }}>Change event</span>
        </button>
        <div style={{ fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.3)", textTransform: "uppercase", letterSpacing: 2, marginBottom: 3 }}>Now Scanning</div>
        <h2 style={{ fontSize: 18, fontWeight: 900, color: "white", lineHeight: 1.3 }}>{title}</h2>
        <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginTop: 2 }}>{meta}</div>
      </div>

      {/* Viewfinder */}
      <div style={{ flex: 1, margin: "0 12px", borderRadius: 24, overflow: "hidden", position: "relative", background: "#0a1410", display: "flex", alignItems: "center", justifyContent: "center" }}>
        {/* Camera background */}
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at center, #1a3027 0%, #080e0b 100%)" }} />

        {/* Corner brackets */}
        {[
          { top: "calc(50% - 100px)", left: "calc(50% - 100px)", borderTop: `3px solid ${B}`, borderLeft: `3px solid ${B}` },
          { top: "calc(50% - 100px)", right: "calc(50% - 100px)", borderTop: `3px solid ${B}`, borderRight: `3px solid ${B}` },
          { bottom: "calc(50% - 100px)", left: "calc(50% - 100px)", borderBottom: `3px solid ${B}`, borderLeft: `3px solid ${B}` },
          { bottom: "calc(50% - 100px)", right: "calc(50% - 100px)", borderBottom: `3px solid ${B}`, borderRight: `3px solid ${B}` },
        ].map((s, i) => (
          <div key={i} style={{ position: "absolute", width: 36, height: 36, borderRadius: 2, ...s }} />
        ))}

        {/* Inner dim box */}
        <div style={{ position: "absolute", width: 200, height: 200, borderRadius: 8, background: `${B}12` }} />

        {/* Scan line */}
        <div style={{ position: "absolute", width: 190, overflow: "hidden", height: 190 }}>
          <div className="scan-line" style={{ position: "absolute", left: 0, right: 0, height: 2, background: `linear-gradient(to right, transparent, ${B}, transparent)`, boxShadow: `0 0 12px ${B}` }} />
        </div>

        {/* Instructions */}
        <div style={{ position: "absolute", bottom: 24, left: 0, right: 0, textAlign: "center" }}>
          <p style={{ color: "rgba(255,255,255,0.5)", fontSize: 13, fontWeight: 600 }}>Align QR code within the frame</p>
        </div>
      </div>

      {/* Controls */}
      <div style={{ padding: "20px 20px 28px", display: "flex", alignItems: "center", justifyContent: "space-around" }}>
        <button style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
          <div style={{ width: 52, height: 52, borderRadius: 999, background: "rgba(255,255,255,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Zap size={22} color="white" />
          </div>
          <span style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.4)" }}>Flash</span>
        </button>

        <button style={{ width: 68, height: 68, borderRadius: 999, border: "3px solid rgba(255,255,255,0.25)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Camera size={28} color="white" />
        </button>

        {/* Simulate scan */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
          <div style={{ display: "flex", gap: 4 }}>
            <button onClick={() => nav("scan-valid")} style={{ width: 22, height: 22, borderRadius: 6, background: "rgba(16,183,127,0.3)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Check size={10} color={B} strokeWidth={3} />
            </button>
            <button onClick={() => nav("scan-used")} style={{ width: 22, height: 22, borderRadius: 6, background: "rgba(245,158,11,0.3)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <AlarmClock size={10} color="#f59e0b" />
            </button>
            <button onClick={() => nav("scan-invalid")} style={{ width: 22, height: 22, borderRadius: 6, background: "rgba(239,68,68,0.3)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <X size={10} color="#ef4444" strokeWidth={3} />
            </button>
          </div>
          <span style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.4)" }}>Simulate</span>
        </div>
      </div>

      <style>{`
        .scan-line {
          animation: scanMove 2.2s ease-in-out infinite;
        }
        @keyframes scanMove {
          0%   { top: 5%;  opacity: 0.9; }
          50%  { top: 88%; opacity: 1;   }
          100% { top: 5%;  opacity: 0.9; }
        }
      `}</style>
    </div>
  );
}

// ─── SCAN RESULT ──────────────────────────────────────────────────────────────
function ScanResultScreen({ result, nav }: { result: "valid" | "used" | "invalid"; nav: (s: Screen) => void }) {
  useEffect(() => {
    const t = setTimeout(() => nav("scanner"), 5000);
    return () => clearTimeout(t);
  }, [nav, result]);

  const cfg = {
    valid: {
      bg: B,
      iconBg: "rgba(255,255,255,0.18)",
      icon: <CheckCircle size={72} color="white" strokeWidth={1.5} />,
      badge: "✓ ADMIT",
      badgeBg: "rgba(255,255,255,0.2)",
      title: "Admit",
      sub: "Ticket is valid",
      name: "Amina Hassan",
      detail: "General Admission · EKD-7412",
    },
    used: {
      bg: "#d97706",
      iconBg: "rgba(255,255,255,0.18)",
      icon: <AlarmClock size={72} color="white" strokeWidth={1.5} />,
      badge: "⚠ ALREADY USED",
      badgeBg: "rgba(255,255,255,0.2)",
      title: "Already Checked In",
      sub: "This ticket was already scanned",
      name: "Mohamed Ali",
      detail: "Checked in at 6:47 PM · EKD-7413",
    },
    invalid: {
      bg: "#dc2626",
      iconBg: "rgba(255,255,255,0.18)",
      icon: <XCircle size={72} color="white" strokeWidth={1.5} />,
      badge: "✕ INVALID",
      badgeBg: "rgba(255,255,255,0.2)",
      title: "Invalid Ticket",
      sub: "Do not admit this person",
      name: null,
      detail: "Ticket not recognized in the system",
    },
  }[result];

  return (
    <div className="flex flex-col h-full" style={{ background: cfg.bg }}>
      <StatusBar light />
      <div className="flex-1 flex flex-col items-center justify-center gap-6 px-8">
        {/* Icon */}
        <div style={{ width: 136, height: 136, borderRadius: 999, background: cfg.iconBg, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {cfg.icon}
        </div>

        {/* Badge */}
        <div style={{ background: "rgba(0,0,0,0.15)", borderRadius: 999, padding: "6px 20px" }}>
          <span style={{ color: "white", fontSize: 12, fontWeight: 900, letterSpacing: 2 }}>{cfg.badge}</span>
        </div>

        {/* Text */}
        <div style={{ textAlign: "center" }}>
          <h1 style={{ fontSize: 36, fontWeight: 900, color: "white", lineHeight: 1.1 }}>{cfg.title}</h1>
          <p style={{ color: "rgba(255,255,255,0.65)", fontSize: 15, marginTop: 8 }}>{cfg.sub}</p>
        </div>

        {/* Info card */}
        <div style={{ width: "100%", background: "rgba(255,255,255,0.15)", borderRadius: 22, padding: "18px 20px", backdropFilter: "blur(8px)" }}>
          {cfg.name && (
            <div style={{ fontSize: 22, fontWeight: 900, color: "white", marginBottom: 6, textAlign: "center" }}>{cfg.name}</div>
          )}
          <div style={{ fontSize: 14, color: "rgba(255,255,255,0.7)", textAlign: "center" }}>{cfg.detail}</div>
        </div>
      </div>

      {/* Actions */}
      <div style={{ padding: "0 24px 32px" }}>
        <p style={{ textAlign: "center", fontSize: 12, color: "rgba(255,255,255,0.4)", marginBottom: 14, fontWeight: 600 }}>
          Auto-returning to scanner in 5 seconds…
        </p>
        <button
          onClick={() => nav("scanner")}
          style={{ width: "100%", background: "rgba(255,255,255,0.2)", borderRadius: 20, padding: "17px 0", color: "white", fontWeight: 800, fontSize: 16, marginBottom: 12 }}
        >
          Scan Next
        </button>
        <div className="flex justify-center gap-3">
          {(["scan-valid", "scan-used", "scan-invalid"] as const).map((s, i) => {
            const labels = ["Valid", "Used", "Invalid"];
            const colors = [B, "#d97706", "#dc2626"];
            return (
              <button
                key={s}
                onClick={() => nav(s)}
                style={{ padding: "6px 14px", borderRadius: 12, background: "rgba(0,0,0,0.15)", fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.5)", border: result === s.replace("scan-", "") ? "1px solid rgba(255,255,255,0.4)" : "none" }}
              >
                {labels[i]}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ─── NAVIGATION HUB ───────────────────────────────────────────────────────────
function NavBar({ current, nav }: { current: Screen; nav: (s: Screen) => void }) {
  const screens: Screen[] = [
    "splash", "onboarding", "login", "register",
    "home", "search", "event-detail", "ticket-selection",
    "checkout", "checkout-processing", "checkout-failed",
    "order-confirmation", "my-tickets", "ticket-view", "profile",
    "staff-login", "scanner", "scan-valid", "scan-used", "scan-invalid",
  ];
  const labels: Record<Screen, string> = {
    splash: "Splash", onboarding: "Onboarding", login: "Login", register: "Register",
    home: "Home", search: "Search", "event-detail": "Event", "ticket-selection": "Tickets",
    checkout: "Checkout", "checkout-processing": "Processing", "checkout-failed": "Failed",
    "order-confirmation": "Confirmed", "my-tickets": "My Tickets", "ticket-view": "Ticket QR", profile: "Profile",
    "staff-login": "Staff Login", "staff-events": "Select Event", scanner: "Scanner", "scan-valid": "Valid", "scan-used": "Used", "scan-invalid": "Invalid",
  };
  const groups = [
    { label: "Customer", screens: ["splash", "onboarding", "login", "register", "home", "search", "event-detail", "ticket-selection", "checkout", "checkout-processing", "checkout-failed", "order-confirmation", "my-tickets", "ticket-view", "profile"] as Screen[] },
    { label: "Staff", screens: ["staff-login", "staff-events", "scanner", "scan-valid", "scan-used", "scan-invalid"] as Screen[] },
  ];
  return (
    <div style={{ width: 200, height: "100%", background: "#0a1410", flexShrink: 0, overflowY: "auto", padding: "24px 0", boxSizing: "border-box" }}>
      <div style={{ padding: "0 16px 16px", borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: B, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ticket size={16} color="white" strokeWidth={2} />
          </div>
          <div>
            <div style={{ fontWeight: 900, fontSize: 15, color: "white" }}>Ekaadh</div>
            <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", fontWeight: 600 }}>Design Preview</div>
          </div>
        </div>
      </div>
      {groups.map((g) => (
        <div key={g.label} style={{ padding: "14px 0 4px" }}>
          <div style={{ padding: "0 16px 8px", fontSize: 10, fontWeight: 800, color: "rgba(255,255,255,0.25)", textTransform: "uppercase", letterSpacing: 1.5 }}>
            {g.label}
          </div>
          {g.screens.map((s) => (
            <button
              key={s}
              onClick={() => nav(s)}
              style={{
                width: "100%",
                padding: "9px 16px",
                textAlign: "left",
                fontSize: 13,
                fontWeight: current === s ? 800 : 500,
                color: current === s ? "white" : "rgba(255,255,255,0.4)",
                background: current === s ? `${B}25` : "transparent",
                borderLeft: current === s ? `3px solid ${B}` : "3px solid transparent",
                display: "block",
              }}
            >
              {labels[s]}
            </button>
          ))}
        </div>
      ))}
    </div>
  );
}

// ─── APP ──────────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState<Screen>("splash");
  const [evtId, setEvtId] = useState("1");
  const [staffEvtId, setStaffEvtId] = useState<string | null>(null);
  const nav = (s: Screen) => setScreen(s);
  const ev = EVENTS.find((e) => e.id === evtId) ?? EVENTS[0];
  const staffEv = STAFF_EVENTS.find((e) => e.id === staffEvtId) ?? null;

  const renderScreen = () => {
    switch (screen) {
      case "splash": return <SplashScreen nav={nav} />;
      case "onboarding": return <OnboardingScreen nav={nav} />;
      case "login": return <LoginScreen nav={nav} />;
      case "register": return <RegisterScreen nav={nav} />;
      case "home": return <HomeScreen nav={nav} setEvt={setEvtId} />;
      case "search": return <SearchScreen nav={nav} setEvt={setEvtId} />;
      case "event-detail": return <EventDetailScreen ev={ev} nav={nav} />;
      case "ticket-selection": return <TicketSelectionScreen ev={ev} nav={nav} />;
      case "checkout": return <CheckoutScreen ev={ev} nav={nav} />;
      case "checkout-processing": return <ProcessingScreen nav={nav} />;
      case "checkout-failed": return <PaymentFailedScreen nav={nav} />;
      case "order-confirmation": return <OrderConfirmationScreen ev={ev} nav={nav} />;
      case "my-tickets": return <MyTicketsScreen nav={nav} />;
      case "ticket-view": return <TicketViewScreen nav={nav} />;
      case "profile": return <ProfileScreen nav={nav} />;
      case "staff-login": return <StaffLoginScreen nav={nav} />;
      case "staff-events": return <StaffEventSelectScreen nav={nav} setStaffEvent={setStaffEvtId} />;
      case "scanner": return <ScannerScreen nav={nav} staffEv={staffEv} />;
      case "scan-valid": return <ScanResultScreen result="valid" nav={nav} />;
      case "scan-used": return <ScanResultScreen result="used" nav={nav} />;
      case "scan-invalid": return <ScanResultScreen result="invalid" nav={nav} />;
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #080e0b 0%, #0f1a15 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "'Plus Jakarta Sans', sans-serif",
        gap: 32,
        padding: "32px 24px",
      }}
    >
      {/* Sidebar nav */}
      <div style={{ borderRadius: 20, overflow: "hidden", height: 812, boxShadow: "0 20px 60px rgba(0,0,0,0.4)", display: "flex", flexDirection: "column" }}>
        <NavBar current={screen} nav={nav} />
      </div>

      {/* Phone */}
      <div style={{ position: "relative", flexShrink: 0 }}>
        {/* Side buttons */}
        <div style={{ position: "absolute", left: -5, top: 100, width: 4, height: 32, background: "#1a2520", borderRadius: "2px 0 0 2px" }} />
        <div style={{ position: "absolute", left: -5, top: 148, width: 4, height: 56, background: "#1a2520", borderRadius: "2px 0 0 2px" }} />
        <div style={{ position: "absolute", left: -5, top: 218, width: 4, height: 56, background: "#1a2520", borderRadius: "2px 0 0 2px" }} />
        <div style={{ position: "absolute", right: -5, top: 160, width: 4, height: 72, background: "#1a2520", borderRadius: "0 2px 2px 0" }} />

        {/* Device shell */}
        <div
          style={{
            borderRadius: 52,
            padding: 4,
            background: "linear-gradient(145deg, #1e2d26, #0d1510)",
            boxShadow: "0 0 0 1px rgba(255,255,255,0.07), 0 40px 100px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.05)",
          }}
        >
          <div
            style={{
              width: 375,
              height: 812,
              borderRadius: 48,
              overflow: "hidden",
              position: "relative",
              background: "white",
            }}
          >
            {/* Dynamic Island */}
            <div
              style={{
                position: "absolute",
                top: 12,
                left: "50%",
                transform: "translateX(-50%)",
                width: 126,
                height: 34,
                background: "#080e0b",
                borderRadius: 20,
                zIndex: 100,
              }}
            />

            {/* Screen */}
            <div style={{ position: "absolute", inset: 0, overflowY: "hidden", overflowX: "hidden" }}>
              {renderScreen()}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
