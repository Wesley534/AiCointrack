import { useState } from "react";

const screens = {
  onboarding: [
    { id: "splash", label: "Splash / Welcome" },
    { id: "onboarding1", label: "Onboarding – Auto Logging" },
    { id: "onboarding2", label: "Onboarding – Base Sync" },
    { id: "register", label: "Register" },
    { id: "login", label: "Login" },
    { id: "setup1", label: "Setup – Monthly Income" },
    { id: "setup2", label: "Setup – Budget Allocation" },
    { id: "setup3", label: "Setup – Savings Goal" },
  ],
  main: [
    { id: "dashboard", label: "Dashboard" },
    { id: "budget", label: "Budget Overview" },
    { id: "category", label: "Category Detail" },
    { id: "transactions", label: "Transactions" },
    { id: "addtx", label: "Add Transaction" },
    { id: "shopping", label: "Shopping Lists" },
    { id: "shoppingdetail", label: "Shopping List Detail" },
    { id: "savings", label: "Savings Goals" },
    { id: "closeout", label: "Month Closeout" },
    { id: "settings", label: "Settings" },
    { id: "miniapp", label: "Base Miniapp View" },
  ],
};

const allScreens = [...screens.onboarding, ...screens.main];

// ── MINT LEDGER PALETTE ──────────────────────────────────────────────────────
const p = {
  bg:        "#FFFFFF",
  bg2:       "#F4F7F5",
  bg3:       "#EBF5F0",
  card:      "#FFFFFF",
  border:    "#E0EDE7",
  borderMid: "#C8DDD4",
  green:     "#00A86B",
  greenDim:  "#007A4D",
  greenBg:   "#E8F9F2",
  indigo:    "#4F46E5",
  indigoBg:  "#EEF2FF",
  amber:     "#D97706",
  amberBg:   "#FFF4E6",
  red:       "#DC2626",
  redBg:     "#FEF0F0",
  text:      "#0F1F17",
  mid:       "#4A6358",
  muted:     "#8FA89C",
  white:     "#FFFFFF",
};

const css = `
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=Outfit:wght@300;400;500;600&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #E8EFF0; font-family: 'Outfit', sans-serif; color: ${p.text}; }
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: ${p.bg2}; }
  ::-webkit-scrollbar-thumb { background: ${p.border}; border-radius: 4px; }

  .screen-phone {
    width: 375px; min-height: 720px; background: ${p.bg};
    border-radius: 40px; overflow: hidden; position: relative;
    border: 1.5px solid ${p.border};
    box-shadow: 0 32px 64px rgba(0,80,50,0.10), 0 2px 8px rgba(0,80,50,0.06), 0 0 0 1px rgba(255,255,255,0.9);
  }
  .status-bar {
    display: flex; justify-content: space-between; align-items: center;
    padding: 12px 24px 8px; font-size: 11px; color: ${p.muted};
    font-family: 'Syne', sans-serif; font-weight: 600;
  }

  .pill { background: ${p.bg2}; border: 1px solid ${p.border}; border-radius: 999px; padding: 3px 10px; font-size: 11px; color: ${p.mid}; }
  .pill-green { background: ${p.greenBg}; border: 1px solid rgba(0,168,107,0.25); color: ${p.green}; }
  .pill-warn  { background: ${p.amberBg}; border: 1px solid rgba(217,119,6,0.25); color: ${p.amber}; }
  .pill-red   { background: ${p.redBg};   border: 1px solid rgba(220,38,38,0.25); color: ${p.red}; }
  .pill-indigo{ background: ${p.indigoBg};border: 1px solid rgba(79,70,229,0.25); color: ${p.indigo}; }

  .btn-primary {
    background: ${p.green}; color: #fff;
    font-family: 'Syne', sans-serif; font-weight: 700;
    border: none; border-radius: 14px; padding: 14px 28px;
    cursor: pointer; font-size: 14px; width: 100%;
    transition: opacity 0.15s;
  }
  .btn-ghost {
    background: transparent; color: ${p.mid};
    font-family: 'Outfit', sans-serif;
    border: 1.5px solid ${p.border}; border-radius: 14px;
    padding: 12px 28px; cursor: pointer; font-size: 13px; width: 100%;
  }
  .input-field {
    background: ${p.bg2}; border: 1.5px solid ${p.border}; border-radius: 12px;
    padding: 12px 16px; color: ${p.text};
    font-family: 'Outfit', sans-serif; font-size: 14px; width: 100%; outline: none;
  }
  .input-label {
    font-size: 11px; color: ${p.mid}; margin-bottom: 6px;
    font-family: 'Syne', sans-serif; font-weight: 700;
    letter-spacing: 0.06em; text-transform: uppercase;
  }
  .section-title { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 16px; color: ${p.text}; }
  .nav-bar {
    position: absolute; bottom: 0; left: 0; right: 0;
    background: ${p.white}; border-top: 1px solid ${p.border};
    display: flex; justify-content: space-around; padding: 10px 0 20px;
    box-shadow: 0 -4px 16px rgba(0,0,0,0.04);
  }
  .nav-item { display: flex; flex-direction: column; align-items: center; gap: 3px; font-size: 9px; color: ${p.muted}; cursor: pointer; font-family: 'Outfit', sans-serif; font-weight: 500; }
  .nav-item.active { color: ${p.green}; }
  .progress-bar { background: ${p.bg3}; border-radius: 999px; height: 6px; overflow: hidden; }
  .progress-fill { height: 100%; border-radius: 999px; background: ${p.green}; }
  .variance-green { color: ${p.green}; }
  .variance-red { color: ${p.red}; }
  .card-block { background: ${p.white}; border: 1px solid ${p.border}; border-radius: 16px; padding: 16px; }
  .card-tinted { background: ${p.bg2}; border: 1px solid ${p.border}; border-radius: 16px; padding: 16px; }
  .tag { font-size: 10px; font-family: 'Syne', sans-serif; font-weight: 700; padding: 2px 8px; border-radius: 99px; }
  .tag-need { background: ${p.indigoBg}; color: ${p.indigo}; border: 1px solid rgba(79,70,229,0.2); }
  .tag-want { background: ${p.amberBg}; color: ${p.amber}; border: 1px solid rgba(217,119,6,0.2); }
  .tag-save { background: ${p.greenBg}; color: ${p.green}; border: 1px solid rgba(0,168,107,0.2); }
  .chain-badge {
    background: ${p.indigoBg}; border: 1px solid rgba(79,70,229,0.2);
    border-radius: 8px; padding: 8px 12px;
    display: flex; align-items: center; gap: 8px; font-size: 12px; color: ${p.mid};
  }
  .divider { height: 1px; background: ${p.border}; margin: 12px 0; }
  .hero-card {
    background: linear-gradient(135deg, ${p.green} 0%, #00c48c 100%);
    border-radius: 20px; padding: 20px;
    box-shadow: 0 8px 24px rgba(0,168,107,0.25);
  }
  .ai-card {
    background: ${p.indigoBg}; border: 1px solid rgba(79,70,229,0.2);
    border-radius: 14px; padding: 14px;
  }
`;

// ── STATUS BAR ────────────────────────────────────────────────────────────────
function StatusBar() {
  return (
    <div className="status-bar">
      <span>9:41</span><span style={{ color: p.green }}>●●●</span><span>100%</span>
    </div>
  );
}

// ── NAV BAR ────────────────────────────────────────────────────────────────────
function NavBar({ active }) {
  const items = [
    { id: "home", icon: "🏠", label: "Home" },
    { id: "budget", icon: "📊", label: "Budget" },
    { id: "tx", icon: "💸", label: "Transact" },
    { id: "shop", icon: "🛒", label: "Shopping" },
    { id: "save", icon: "🎯", label: "Savings" },
  ];
  return (
    <div className="nav-bar">
      {items.map(i => (
        <div key={i.id} className={`nav-item ${active === i.id ? "active" : ""}`}>
          <span style={{ fontSize: 18 }}>{i.icon}</span>
          <span>{i.label}</span>
        </div>
      ))}
    </div>
  );
}

// ── SCREENS ───────────────────────────────────────────────────────────────────

function Splash() {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100%", padding: "40px 32px", gap: 24, background: p.bg }}>
      <div style={{ width: 84, height: 84, borderRadius: 26, background: `linear-gradient(135deg, ${p.green} 0%, #00c48c 100%)`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 38, boxShadow: `0 12px 32px rgba(0,168,107,0.3)` }}>💰</div>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 34, color: p.text, letterSpacing: "-0.02em" }}>PocketPal</div>
        <div style={{ color: p.mid, fontSize: 14, marginTop: 8, lineHeight: 1.6, fontWeight: 300 }}>Your AI-powered money companion — tracks every shilling, automatically.</div>
      </div>
      <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 10, marginTop: 8 }}>
        <button className="btn-primary">Get Started</button>
        <button className="btn-ghost">I already have an account</button>
      </div>
      <div className="chain-badge" style={{ width: "100%" }}>
        <span style={{ width: 8, height: 8, borderRadius: "50%", background: p.green, display: "inline-block" }}></span>
        <span>Powered by <strong style={{ color: p.indigo }}>Base</strong> — your money lives onchain</span>
      </div>
    </div>
  );
}

function Onboarding1() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", background: p.bg }}>
      <div style={{ display: "flex", gap: 6, marginBottom: 36 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i === 1 ? p.green : p.border }}></div>)}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 48, marginBottom: 18 }}>🔔</div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 24, lineHeight: 1.2, marginBottom: 10, color: p.text }}>Never log expenses manually again</div>
        <div style={{ color: p.mid, fontSize: 14, lineHeight: 1.6, marginBottom: 24, fontWeight: 300 }}>PocketPal reads your M-Pesa, email, and notification alerts to auto-log transactions the moment they happen.</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {[
            ["📱 M-Pesa & SMS auto-detection", p.greenBg, p.green],
            ["📧 MiniSend email notification parsing", p.indigoBg, p.indigo],
            ["⛓️ Base blockchain transaction sync", p.indigoBg, p.indigo],
            ["🤖 AI categorizes every transaction", p.greenBg, p.green],
          ].map(([f, bg, col]) => (
            <div key={f} style={{ background: bg, border: `1px solid ${col}22`, borderRadius: 12, padding: "10px 14px", fontSize: 13, color: p.text, fontWeight: 500 }}>{f}</div>
          ))}
        </div>
      </div>
      <button className="btn-primary" style={{ marginTop: 24 }}>Next →</button>
    </div>
  );
}

function Onboarding2() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", background: p.bg }}>
      <div style={{ display: "flex", gap: 6, marginBottom: 36 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i <= 2 ? p.green : p.border }}></div>)}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 48, marginBottom: 18 }}>⛓️</div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 24, lineHeight: 1.2, marginBottom: 10, color: p.text }}>Your transactions, stored on Base</div>
        <div style={{ color: p.mid, fontSize: 14, lineHeight: 1.6, marginBottom: 24, fontWeight: 300 }}>Every expense you log is recorded onchain — transparent, verifiable, and yours forever.</div>
        <div className="card-tinted" style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, color: p.muted, marginBottom: 8, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase" }}>LATEST ON-CHAIN ACTIVITY</div>
          {[
            { desc: "Groceries – Carrefour", amt: "-Ksh 2,400", cat: "🛒 Food", pos: false },
            { desc: "Received – MiniSend", amt: "+Ksh 5,000", cat: "💸 Income", pos: true },
          ].map(t => (
            <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "9px 0", borderBottom: `1px solid ${p.border}` }}>
              <div>
                <div style={{ fontSize: 13, color: p.text, fontWeight: 500 }}>{t.desc}</div>
                <div style={{ fontSize: 11, color: p.muted }}>{t.cat}</div>
              </div>
              <div style={{ fontSize: 13, color: t.pos ? p.green : p.red, fontFamily: "Syne", fontWeight: 700 }}>{t.amt}</div>
            </div>
          ))}
        </div>
        <div className="chain-badge">
          <span>🔷</span>
          <span>Stored on <strong style={{ color: p.indigo }}>Base L2</strong> — fast, cheap, secure</span>
        </div>
      </div>
      <button className="btn-primary" style={{ marginTop: 24 }}>Let's set up your budget →</button>
    </div>
  );
}

function Register() {
  return (
    <div style={{ padding: "40px 28px", display: "flex", flexDirection: "column", gap: 18, background: p.bg }}>
      <div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, color: p.text, marginBottom: 4 }}>Create account</div>
        <div style={{ color: p.mid, fontSize: 13, fontWeight: 300 }}>Start managing your money smarter</div>
      </div>
      {[["Full Name", "John Doe"], ["Email", "john@example.com"], ["Password", "••••••••"]].map(([label, ph]) => (
        <div key={label}>
          <div className="input-label">{label}</div>
          <input className="input-field" placeholder={ph} readOnly />
        </div>
      ))}
      <button className="btn-primary">Create Account</button>
      <div style={{ textAlign: "center", color: p.muted, fontSize: 12 }}>— or sign up with —</div>
      <button className="btn-ghost" style={{ border: `1.5px solid rgba(79,70,229,0.3)`, color: p.indigo }}>🔵 Continue with Base Wallet</button>
      <div style={{ textAlign: "center", color: p.muted, fontSize: 12 }}>Already have an account? <span style={{ color: p.green, fontWeight: 600 }}>Log in</span></div>
    </div>
  );
}

function Login() {
  return (
    <div style={{ padding: "40px 28px", display: "flex", flexDirection: "column", gap: 18, height: "100%", justifyContent: "center", background: p.bg }}>
      <div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, color: p.text, marginBottom: 4 }}>Welcome back 👋</div>
        <div style={{ color: p.mid, fontSize: 13, fontWeight: 300 }}>Log back into your PocketPal</div>
      </div>
      {[["Email", "john@example.com"], ["Password", "••••••••"]].map(([label, ph]) => (
        <div key={label}>
          <div className="input-label">{label}</div>
          <input className="input-field" placeholder={ph} readOnly />
        </div>
      ))}
      <button className="btn-primary">Log In</button>
      <button className="btn-ghost" style={{ border: `1.5px solid rgba(79,70,229,0.3)`, color: p.indigo }}>🔵 Log in with Base Wallet</button>
      <div style={{ textAlign: "center", color: p.muted, fontSize: 12 }}><span style={{ color: p.green, fontWeight: 600 }}>Forgot password?</span></div>
    </div>
  );
}

function Setup1() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", background: p.bg }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i === 1 ? p.green : p.border }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 4, color: p.text }}>Step 1: Monthly Income</div>
      <div style={{ color: p.mid, fontSize: 13, marginBottom: 28, fontWeight: 300 }}>Tell us how much you earn each month so we can build your budget.</div>
      <div>
        <div className="input-label">Monthly Income (Ksh)</div>
        <div style={{ background: p.greenBg, border: `1.5px solid ${p.green}`, borderRadius: 12, padding: "14px 16px", display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ color: p.mid, fontSize: 14 }}>Ksh</span>
          <span style={{ color: p.text, fontSize: 22, fontFamily: "Syne", fontWeight: 800 }}>85,000</span>
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 20 }}>
        <div className="card-tinted" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ color: p.mid, fontSize: 13, fontWeight: 500 }}>Salary</span>
          <span style={{ color: p.green, fontFamily: "Syne", fontWeight: 700, fontSize: 14 }}>Ksh 85,000</span>
        </div>
        <button style={{ background: "none", border: `1.5px dashed ${p.border}`, borderRadius: 12, padding: 12, color: p.muted, fontSize: 13, cursor: "pointer", fontFamily: "Outfit" }}>+ Add another income source</button>
      </div>
      <button className="btn-primary" style={{ marginTop: "auto" }}>Next →</button>
    </div>
  );
}

function Setup2() {
  const cats = [["🍔 Food", 20, "need"], ["🏠 Rent", 35, "need"], ["🚗 Transport", 10, "need"], ["🎉 Entertainment", 15, "want"], ["💰 Savings", 20, "save"]];
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", overflow: "auto", background: p.bg }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i <= 2 ? p.green : p.border }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 4, color: p.text }}>Step 2: Budget Allocation</div>
      <div style={{ color: p.mid, fontSize: 13, marginBottom: 16, fontWeight: 300 }}>We've applied the 50/30/20 rule. Adjust as needed.</div>
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <button className="pill pill-green" style={{ cursor: "pointer", fontFamily: "Syne", fontWeight: 700 }}>50/30/20</button>
        <button className="pill" style={{ cursor: "pointer" }}>Manual</button>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {cats.map(([cat, pct, type]) => (
          <div key={cat} className="card-tinted" style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                <span style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{cat}</span>
                <span className={`tag tag-${type}`}>{type}</span>
              </div>
              <div className="progress-bar"><div className="progress-fill" style={{ width: `${pct}%` }}></div></div>
            </div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14, minWidth: 36, textAlign: "right", color: p.green }}>{pct}%</div>
          </div>
        ))}
      </div>
      <button className="btn-primary" style={{ marginTop: 16 }}>Next →</button>
    </div>
  );
}

function Setup3() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", background: p.bg }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: p.green }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 4, color: p.text }}>Step 3: Savings Goal 🎯</div>
      <div style={{ color: p.mid, fontSize: 13, marginBottom: 24, fontWeight: 300 }}>What are you saving towards?</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {[["Emergency Fund", "6 months expenses", "🛡️", true], ["Vacation", "Trip to Mombasa", "✈️", false], ["New Laptop", "MacBook Pro", "💻", false]].map(([name, desc, icon, sel]) => (
          <div key={name} style={{ background: sel ? p.greenBg : p.bg2, border: `1.5px solid ${sel ? p.green : p.border}`, borderRadius: 14, padding: "14px 16px", display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}>
            <span style={{ fontSize: 24 }}>{icon}</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontFamily: "Syne", fontWeight: 700, color: p.text }}>{name}</div>
              <div style={{ fontSize: 12, color: p.mid, fontWeight: 300 }}>{desc}</div>
            </div>
            {sel && <span className="pill pill-green">Selected ✓</span>}
          </div>
        ))}
        <button style={{ background: "none", border: `1.5px dashed ${p.border}`, borderRadius: 12, padding: 12, color: p.muted, fontSize: 13, cursor: "pointer", fontFamily: "Outfit" }}>+ Create custom goal</button>
      </div>
      <button className="btn-primary" style={{ marginTop: "auto" }}>Go to Dashboard →</button>
    </div>
  );
}

function Dashboard() {
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      {/* Header */}
      <div style={{ background: p.bg, padding: "20px 20px 0", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div>
            <div style={{ color: p.muted, fontSize: 12, fontWeight: 400 }}>Good morning,</div>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20, color: p.text }}>John Kamau 👋</div>
          </div>
          <div style={{ width: 42, height: 42, borderRadius: "50%", background: `linear-gradient(135deg, ${p.green}, #00c48c)`, display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontFamily: "Syne", fontWeight: 800, fontSize: 16, boxShadow: `0 4px 12px rgba(0,168,107,0.3)` }}>J</div>
        </div>
      </div>

      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 14 }}>
        {/* Hero Balance Card */}
        <div className="hero-card">
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.75)", marginBottom: 4, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase" }}>FREE TO SPEND</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 34, color: "#fff", marginBottom: 4 }}>Ksh 24,500</div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", marginBottom: 14 }}>↑ Ksh 2,300 vs last month</div>
          <div style={{ background: "rgba(255,255,255,0.25)", borderRadius: 99, height: 5, marginBottom: 6 }}>
            <div style={{ width: "26%", height: "100%", background: "#fff", borderRadius: 99 }}></div>
          </div>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.7)" }}>March 8 of 31</div>
        </div>

        {/* Quick Stats */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {[["Total Budget", "Ksh 85,000", p.text], ["Spent So Far", "Ksh 60,500", p.red], ["Saved", "Ksh 17,000", p.green], ["Shopping", "3 lists", p.indigo]].map(([label, val, col]) => (
            <div key={label} className="card-block">
              <div style={{ fontSize: 11, color: p.muted, marginBottom: 4, fontWeight: 500 }}>{label}</div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 16, color: col }}>{val}</div>
            </div>
          ))}
        </div>

        {/* AI Insight */}
        <div className="ai-card">
          <div style={{ fontSize: 11, color: p.indigo, fontFamily: "Syne", fontWeight: 700, marginBottom: 6, letterSpacing: "0.06em" }}>🤖 AI INSIGHT</div>
          <div style={{ fontSize: 13, lineHeight: 1.5, color: p.text, fontWeight: 300 }}>You're on track this month! Food spending is <span style={{ color: p.amber, fontWeight: 600 }}>18% over budget</span>. Reduce dining out by Ksh 800 to stay in the green.</div>
        </div>

        {/* Recent Transactions */}
        <div>
          <div className="section-title" style={{ marginBottom: 10, fontSize: 14 }}>Recent Transactions</div>
          <div className="card-block" style={{ padding: "4px 16px" }}>
            {[
              { desc: "Uber – CBD to Westlands", cat: "🚗 Transport", amt: "-Ksh 350", source: "auto", pos: false },
              { desc: "Quickmart Supermarket", cat: "🛒 Food", amt: "-Ksh 1,840", source: "auto", pos: false },
              { desc: "MiniSend – Received", cat: "💸 Income", amt: "+Ksh 5,000", source: "chain", pos: true },
            ].map(t => (
              <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${p.border}` }}>
                <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: p.bg2, border: `1px solid ${p.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>{t.cat.split(" ")[0]}</div>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{t.desc}</div>
                    <div style={{ fontSize: 11, color: p.muted, display: "flex", gap: 5, alignItems: "center" }}>
                      {t.cat.split(" ").slice(1).join(" ")}
                      {t.source === "auto" && <span className="pill" style={{ fontSize: 9 }}>Auto</span>}
                      {t.source === "chain" && <span className="pill pill-indigo" style={{ fontSize: 9 }}>Onchain</span>}
                    </div>
                  </div>
                </div>
                <div style={{ fontSize: 13, color: t.pos ? p.green : p.red, fontFamily: "Syne", fontWeight: 700 }}>{t.amt}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <NavBar active="home" />
    </div>
  );
}

function BudgetPage() {
  const cats = [["🍔 Food", 20000, 23600, "need"], ["🏠 Rent", 30000, 30000, "need"], ["🚗 Transport", 8000, 5200, "need"], ["🎉 Entertainment", 12750, 9000, "want"], ["💰 Savings", 17000, 17000, "save"]];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div className="section-title" style={{ fontSize: 20 }}>Budget — March</div>
          <button className="pill pill-green" style={{ fontWeight: 700, cursor: "pointer" }}>+ Category</button>
        </div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
          {[["Planned", "Ksh 87,750", p.mid], ["Actual", "Ksh 84,800", p.amber], ["Remaining", "Ksh 2,950", p.green]].map(([l, v, c]) => (
            <div key={l} className="card-block" style={{ textAlign: "center", padding: "12px 8px" }}>
              <div style={{ fontSize: 10, color: p.muted, marginBottom: 4, fontWeight: 500 }}>{l}</div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: c }}>{v}</div>
            </div>
          ))}
        </div>
        {cats.map(([cat, planned, actual, type]) => {
          const pct = Math.min(100, Math.round((actual / planned) * 100));
          const over = actual > planned;
          return (
            <div key={cat} className="card-block" style={{ border: over ? `1.5px solid ${p.red}33` : `1px solid ${p.border}` }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                <span style={{ fontSize: 14, fontWeight: 500, color: p.text }}>{cat}</span>
                <span className={`tag tag-${type}`}>{type}</span>
              </div>
              <div className="progress-bar" style={{ marginBottom: 8 }}>
                <div className="progress-fill" style={{ width: `${pct}%`, background: over ? p.red : p.green }}></div>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
                <span style={{ color: p.muted }}>Planned: Ksh {planned.toLocaleString()}</span>
                <span style={{ color: over ? p.red : p.green, fontWeight: 600 }}>Actual: Ksh {actual.toLocaleString()}</span>
              </div>
            </div>
          );
        })}
      </div>
      <NavBar active="budget" />
    </div>
  );
}

function CategoryDetail() {
  const txs = [
    { desc: "KFC Westlands", amt: 1200, date: "Mar 6" },
    { desc: "Java House", amt: 850, date: "Mar 4" },
    { desc: "Carrefour Groceries", amt: 3200, date: "Mar 2" },
    { desc: "Pizza Inn", amt: 1400, date: "Mar 1" },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button style={{ background: "none", border: "none", color: p.muted, fontSize: 18, cursor: "pointer" }}>←</button>
          <div className="section-title" style={{ fontSize: 20 }}>🍔 Food</div>
          <span className="tag tag-need" style={{ marginLeft: "auto" }}>need</span>
        </div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ background: p.redBg, border: `1.5px solid ${p.red}33`, borderRadius: 20, padding: 20, textAlign: "center" }}>
          <div style={{ fontSize: 11, color: p.red, marginBottom: 4, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.06em" }}>OVER BUDGET BY</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 28, color: p.red, marginBottom: 4 }}>Ksh 3,600</div>
          <div style={{ fontSize: 12, color: p.mid, fontWeight: 300 }}>Ksh 23,600 spent of Ksh 20,000 planned</div>
          <div className="progress-bar" style={{ marginTop: 14 }}>
            <div className="progress-fill" style={{ width: "100%", background: p.red }}></div>
          </div>
        </div>
        <div className="section-title" style={{ fontSize: 14 }}>Transactions this month</div>
        <div className="card-block" style={{ padding: "4px 16px" }}>
          {txs.map(t => (
            <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: `1px solid ${p.border}` }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{t.desc}</div>
                <div style={{ fontSize: 11, color: p.muted }}>{t.date}</div>
              </div>
              <div style={{ color: p.red, fontFamily: "Syne", fontWeight: 700, fontSize: 13 }}>-Ksh {t.amt.toLocaleString()}</div>
            </div>
          ))}
        </div>
      </div>
      <NavBar active="budget" />
    </div>
  );
}

function Transactions() {
  const txs = [
    { desc: "Uber – CBD to Westlands", cat: "🚗 Transport", amt: "-350", date: "Mar 8", src: "auto", pos: false },
    { desc: "MiniSend – Jane", cat: "💸 Income", amt: "+5,000", date: "Mar 7", src: "chain", pos: true },
    { desc: "Quickmart", cat: "🛒 Food", amt: "-1,840", date: "Mar 7", src: "auto", pos: false },
    { desc: "Netflix", cat: "🎬 Entertainment", amt: "-1,100", date: "Mar 5", src: "manual", pos: false },
    { desc: "Rent – March", cat: "🏠 Rent", amt: "-30,000", date: "Mar 1", src: "manual", pos: false },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
          <div className="section-title" style={{ fontSize: 20 }}>Transactions</div>
          <button className="pill pill-green" style={{ fontWeight: 700, cursor: "pointer" }}>+ Add</button>
        </div>
        <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 4 }}>
          {["All", "Auto-logged", "Onchain", "Manual"].map((f, i) => (
            <button key={f} className={i === 0 ? "pill pill-green" : "pill"} style={{ whiteSpace: "nowrap", cursor: "pointer", fontWeight: i === 0 ? 700 : 400 }}>{f}</button>
          ))}
        </div>
      </div>
      <div style={{ padding: "8px 20px" }}>
        {txs.map(t => (
          <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0", borderBottom: `1px solid ${p.border}` }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: p.bg2, border: `1px solid ${p.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>{t.cat.split(" ")[0]}</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{t.desc}</div>
                <div style={{ display: "flex", gap: 5, alignItems: "center" }}>
                  <span style={{ fontSize: 11, color: p.muted }}>{t.date}</span>
                  {t.src === "auto" && <span className="pill" style={{ fontSize: 9 }}>Auto</span>}
                  {t.src === "chain" && <span className="pill pill-indigo" style={{ fontSize: 9 }}>Onchain</span>}
                  {t.src === "manual" && <span className="pill" style={{ fontSize: 9 }}>Manual</span>}
                </div>
              </div>
            </div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: t.pos ? p.green : p.red }}>Ksh {t.amt}</div>
          </div>
        ))}
      </div>
      <NavBar active="tx" />
    </div>
  );
}

function AddTransaction() {
  return (
    <div style={{ padding: "20px 20px 0", height: "100%", overflow: "auto", background: p.bg }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 24 }}>
        <button style={{ background: "none", border: "none", color: p.muted, fontSize: 18, cursor: "pointer" }}>←</button>
        <div className="section-title" style={{ fontSize: 20 }}>Add Transaction</div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div>
          <div className="input-label">Amount (Ksh)</div>
          <div style={{ background: p.greenBg, border: `1.5px solid ${p.green}`, borderRadius: 12, padding: "14px 16px", display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ color: p.mid }}>Ksh</span>
            <span style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, color: p.text }}>1,200</span>
          </div>
        </div>
        <div>
          <div className="input-label">Description</div>
          <input className="input-field" defaultValue="KFC Westlands" readOnly />
        </div>
        <div>
          <div className="input-label">AI Category Suggestion</div>
          <div style={{ background: p.indigoBg, border: `1.5px solid rgba(79,70,229,0.25)`, borderRadius: 12, padding: 14, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: p.text }}>🍔 Food — Want</div>
              <div style={{ fontSize: 11, color: p.indigo }}>AI confidence: 94%</div>
            </div>
            <button className="pill pill-green" style={{ fontWeight: 700, cursor: "pointer" }}>Accept</button>
          </div>
        </div>
        <div>
          <div className="input-label">Date</div>
          <input className="input-field" defaultValue="March 8, 2025" readOnly />
        </div>
        <div>
          <div className="input-label">Notes (optional)</div>
          <input className="input-field" placeholder="e.g. Team lunch" readOnly />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 0" }}>
          <div style={{ width: 20, height: 20, borderRadius: 5, border: `2px solid ${p.green}`, background: p.greenBg, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ color: p.green, fontSize: 11, fontWeight: 700 }}>✓</span>
          </div>
          <span style={{ fontSize: 13, color: p.mid, fontWeight: 400 }}>Save on Base blockchain</span>
        </div>
        <button className="btn-primary">Log Expense</button>
      </div>
    </div>
  );
}

function ShoppingLists() {
  const lists = [
    { name: "Weekly Groceries", total: 3400, budget: 4000, items: 8, status: "green" },
    { name: "Electronics", total: 48000, budget: 40000, items: 3, status: "red" },
    { name: "Household", total: 1800, budget: 2000, items: 5, status: "yellow" },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div className="section-title" style={{ fontSize: 20 }}>Shopping Lists</div>
          <button className="pill pill-green" style={{ fontWeight: 700, cursor: "pointer" }}>+ New List</button>
        </div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        {lists.map(l => {
          const pct = Math.min(100, Math.round((l.total / l.budget) * 100));
          const fillColor = l.status === "red" ? p.red : l.status === "yellow" ? p.amber : p.green;
          const pillClass = l.status === "red" ? "pill pill-red" : l.status === "yellow" ? "pill pill-warn" : "pill pill-green";
          return (
            <div key={l.name} className="card-block" style={{ border: l.status === "red" ? `1.5px solid ${p.red}33` : l.status === "yellow" ? `1.5px solid ${p.amber}33` : `1px solid ${p.border}` }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                <div className="section-title" style={{ fontSize: 14 }}>{l.name}</div>
                <span className={pillClass}>{l.items} items</span>
              </div>
              <div className="progress-bar" style={{ marginBottom: 8 }}>
                <div className="progress-fill" style={{ width: `${pct}%`, background: fillColor }}></div>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
                <span style={{ color: p.muted }}>Est. Ksh {l.total.toLocaleString()}</span>
                <span style={{ color: p.muted }}>Budget: Ksh {l.budget.toLocaleString()}</span>
              </div>
            </div>
          );
        })}
      </div>
      <NavBar active="shop" />
    </div>
  );
}

function ShoppingDetail() {
  const items = [
    { name: "Rice 5kg", qty: 1, price: 500 }, { name: "Milk x6", qty: 2, price: 200 },
    { name: "Bread", qty: 1, price: 120 }, { name: "Chicken", qty: 1, price: 650 },
    { name: "Tomatoes 1kg", qty: 2, price: 150 },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
          <button style={{ background: "none", border: "none", color: p.muted, fontSize: 18 }}>←</button>
          <div className="section-title" style={{ fontSize: 20 }}>Weekly Groceries</div>
        </div>
        <div style={{ marginLeft: 28 }}><span className="tag tag-need">Linked: Food budget</span></div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          <div className="card-tinted">
            <div style={{ fontSize: 11, color: p.muted, marginBottom: 4, fontWeight: 500 }}>TOTAL ESTIMATED</div>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20, color: p.text }}>Ksh 1,820</div>
          </div>
          <div style={{ background: p.greenBg, border: `1px solid ${p.green}22`, borderRadius: 16, padding: 14 }}>
            <div style={{ fontSize: 11, color: p.muted, marginBottom: 4, fontWeight: 500 }}>REMAINING</div>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20, color: p.green }}>Ksh 2,180</div>
          </div>
        </div>
        <div className="card-block" style={{ padding: "4px 16px" }}>
          {items.map(i => (
            <div key={i.name} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${p.border}` }}>
              <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                <div style={{ width: 26, height: 26, borderRadius: 7, border: `1.5px solid ${p.border}`, background: p.bg2, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, color: p.muted }}>☐</div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{i.name}</div>
                  <div style={{ fontSize: 11, color: p.muted }}>Qty: {i.qty}</div>
                </div>
              </div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: p.text }}>Ksh {i.price}</div>
            </div>
          ))}
        </div>
        <button className="btn-primary">✓ Checkout → Log as Expenses</button>
      </div>
      <NavBar active="shop" />
    </div>
  );
}

function Savings() {
  const goals = [
    { name: "Emergency Fund 🛡️", saved: 34000, target: 100000, monthly: 5000 },
    { name: "Vacation ✈️", saved: 12000, target: 50000, monthly: 3000 },
    { name: "Laptop 💻", saved: 8000, target: 120000, monthly: 10000 },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div className="section-title" style={{ fontSize: 20 }}>Savings Goals</div>
          <button className="pill pill-green" style={{ fontWeight: 700, cursor: "pointer" }}>+ New Goal</button>
        </div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div className="hero-card" style={{ textAlign: "center" }}>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.75)", marginBottom: 4, fontFamily: "Syne", fontWeight: 700 }}>TOTAL SAVED</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 30, color: "#fff" }}>Ksh 54,000</div>
        </div>
        {goals.map(g => {
          const pct = Math.round((g.saved / g.target) * 100);
          return (
            <div key={g.name} className="card-block">
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                <div className="section-title" style={{ fontSize: 14 }}>{g.name}</div>
                <span style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 12, color: p.green }}>{pct}%</span>
              </div>
              <div className="progress-bar" style={{ marginBottom: 8 }}>
                <div className="progress-fill" style={{ width: `${pct}%` }}></div>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: p.muted, marginBottom: 10 }}>
                <span>Ksh {g.saved.toLocaleString()} saved</span>
                <span>Goal: Ksh {g.target.toLocaleString()}</span>
              </div>
              <div className="divider" />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 12, color: p.mid }}>Monthly: Ksh {g.monthly.toLocaleString()}</span>
                <button className="pill pill-green" style={{ cursor: "pointer", fontWeight: 700, fontSize: 11 }}>Contribute</button>
              </div>
            </div>
          );
        })}
      </div>
      <NavBar active="save" />
    </div>
  );
}

function Closeout() {
  return (
    <div style={{ padding: "20px 20px 0", height: "100%", overflow: "auto", background: p.bg2 }}>
      <div style={{ background: p.bg, margin: "-20px -20px 16px", padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div className="section-title" style={{ fontSize: 20 }}>Monthly Closeout</div>
        <div style={{ color: p.muted, fontSize: 13, fontWeight: 300, marginTop: 2 }}>February 2025 summary</div>
      </div>
      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderBottom: `1px solid ${p.border}` }}>
        {["Summary", "Surplus", "Sweep", "New Month"].map((s, i) => (
          <div key={s} style={{ flex: 1, textAlign: "center", fontSize: 11, fontFamily: "Syne", fontWeight: 700, color: i === 0 ? p.green : p.muted, borderBottom: `2px solid ${i === 0 ? p.green : "transparent"}`, paddingBottom: 8, letterSpacing: "0.03em" }}>{s}</div>
        ))}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 14 }}>
        {[["Income", "Ksh 85,000", p.green], ["Expenses", "Ksh 67,200", p.red], ["Saved", "Ksh 12,800", p.green], ["Surplus", "Ksh 5,000", p.amber]].map(([l, v, c]) => (
          <div key={l} className="card-block" style={{ textAlign: "center" }}>
            <div style={{ fontSize: 11, color: p.muted, marginBottom: 4, fontWeight: 500 }}>{l}</div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 16, color: c }}>{v}</div>
          </div>
        ))}
      </div>
      <div className="card-block" style={{ marginBottom: 14 }}>
        <div style={{ fontSize: 13, marginBottom: 10, fontWeight: 600, color: p.text }}>Category Breakdown</div>
        {[["🍔 Food", "over", "-Ksh 3,600"], ["🏠 Rent", "ok", "Ksh 0"], ["🚗 Transport", "saved", "+Ksh 2,800"]].map(([cat, st, diff]) => (
          <div key={cat} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderBottom: `1px solid ${p.border}` }}>
            <span style={{ fontSize: 13, color: p.text, fontWeight: 500 }}>{cat}</span>
            <span style={{ fontSize: 13, color: st === "over" ? p.red : p.green, fontWeight: 700 }}>{diff}</span>
          </div>
        ))}
      </div>
      <button className="btn-primary">Sweep Surplus to Savings →</button>
    </div>
  );
}

function Settings() {
  const toggles = [
    ["Auto-logging (Notifications)", true],
    ["Email Parsing", true],
    ["Blockchain Sync (Base)", true],
    ["AI Categorization", true],
    ["Strict Budget Mode", false],
    ["AI Insights Feed", true],
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80, background: p.bg2 }}>
      <div style={{ background: p.bg, padding: "20px 20px 16px", borderBottom: `1px solid ${p.border}` }}>
        <div className="section-title" style={{ fontSize: 20 }}>Settings</div>
      </div>
      <div style={{ padding: "16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div className="card-block" style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ width: 50, height: 50, borderRadius: "50%", background: `linear-gradient(135deg, ${p.green}, #00c48c)`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, color: "#fff", fontFamily: "Syne", fontWeight: 800, boxShadow: `0 4px 12px rgba(0,168,107,0.25)` }}>J</div>
          <div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 15, color: p.text }}>John Kamau</div>
            <div style={{ fontSize: 12, color: p.muted }}>john@example.com</div>
            <div className="chain-badge" style={{ marginTop: 4, padding: "4px 8px" }}>
              <span style={{ width: 6, height: 6, borderRadius: "50%", background: p.indigo, display: "inline-block" }}></span>
              <span style={{ fontSize: 10 }}>0x3F…9a2c · Base</span>
            </div>
          </div>
        </div>
        <div style={{ fontSize: 11, color: p.muted, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", marginTop: 4 }}>Auto-Logging Preferences</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {toggles.map(([label, on]) => (
            <div key={label} className="card-block" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{label}</span>
              <div style={{ width: 42, height: 24, borderRadius: 99, background: on ? p.green : p.border, position: "relative", cursor: "pointer", transition: "background 0.2s", boxShadow: on ? `0 2px 8px rgba(0,168,107,0.3)` : "none" }}>
                <div style={{ position: "absolute", top: 3, left: on ? 20 : 3, width: 18, height: 18, borderRadius: "50%", background: "#fff", boxShadow: "0 1px 4px rgba(0,0,0,0.15)", transition: "left 0.2s" }}></div>
              </div>
            </div>
          ))}
        </div>
        <button className="btn-ghost" style={{ marginTop: 4 }}>Log out</button>
      </div>
      <NavBar active="home" />
    </div>
  );
}

function MiniApp() {
  return (
    <div style={{ padding: "20px", height: "100%", overflow: "auto", background: p.bg }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 18, color: p.text }}>PocketPal</div>
        <span className="pill pill-indigo" style={{ fontSize: 10, fontWeight: 700 }}>🔵 Base Miniapp</span>
      </div>
      <div className="chain-badge" style={{ marginBottom: 16 }}>
        <span>⛓️</span>
        <span style={{ fontSize: 12 }}>Tracking onchain transactions from your wallet</span>
      </div>
      <div style={{ fontSize: 11, color: p.muted, fontFamily: "Syne", fontWeight: 700, marginBottom: 10, textTransform: "uppercase", letterSpacing: "0.06em" }}>Recent On-chain Activity</div>
      {[
        { desc: "Sent via MiniSend – Alice", amt: "-Ksh 2,000", cat: "🤝 Transfer", onchain: true },
        { desc: "Received – Bob MiniSend", amt: "+Ksh 5,000", cat: "💸 Income", onchain: true },
        { desc: "Manual: Groceries", amt: "-Ksh 1,200", cat: "🛒 Food", onchain: false },
      ].map(t => (
        <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${p.border}` }}>
          <div>
            <div style={{ fontSize: 13, fontWeight: 500, color: p.text }}>{t.desc}</div>
            <div style={{ fontSize: 11, color: p.muted, display: "flex", gap: 6, alignItems: "center" }}>
              {t.cat}
              {t.onchain && <span className="pill pill-indigo" style={{ fontSize: 9, fontWeight: 700 }}>Onchain</span>}
            </div>
          </div>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: t.amt.startsWith("+") ? p.green : p.red }}>{t.amt}</div>
        </div>
      ))}
      <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 20 }}>
        <button className="btn-primary">+ Log Manual Expense</button>
        <button className="btn-ghost">View Full Budget →</button>
      </div>
    </div>
  );
}

// ── SCREEN MAP ────────────────────────────────────────────────────────────────
const screenComponents = {
  splash: Splash, onboarding1: Onboarding1, onboarding2: Onboarding2,
  register: Register, login: Login, setup1: Setup1, setup2: Setup2, setup3: Setup3,
  dashboard: Dashboard, budget: BudgetPage, category: CategoryDetail,
  transactions: Transactions, addtx: AddTransaction,
  shopping: ShoppingLists, shoppingdetail: ShoppingDetail,
  savings: Savings, closeout: Closeout, settings: Settings, miniapp: MiniApp,
};

function Note({ title, items }) {
  return (
    <div>
      <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 12, color: p.text, marginBottom: 8 }}>{title}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
        {items.map(i => (
          <div key={i} style={{ fontSize: 12, color: p.mid, display: "flex", gap: 6 }}>
            <span style={{ color: p.green, flexShrink: 0 }}>→</span>
            <span>{i}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

const notes = {
  splash: ["First impression screen", "Green gradient logo mark", "Base onchain indigo badge"],
  onboarding1: ["Color-coded feature cards", "Green = M-Pesa, Indigo = Base/Email", "3-step progress bar"],
  onboarding2: ["Tinted card for tx preview", "Indigo chain badge", "Live tx feed sample"],
  register: ["Soft mint input fields", "Indigo wallet CTA", "Green link text"],
  login: ["Clean centered layout", "Indigo Base wallet login", "Minimal, trustworthy"],
  setup1: ["Green tinted amount field", "Green border on active input", "Dashed add-source button"],
  setup2: ["Tinted cards for categories", "Green progress bars", "Needs/Wants/Savings tag colors"],
  setup3: ["Green bg on selected goal", "Green border highlight", "Dashed custom goal button"],
  dashboard: ["Green gradient hero card", "White text on green", "AI insight in indigo wash", "Indigo onchain badge on tx"],
  budget: ["Sticky white header", "Mint-tinted bg2 page bg", "Red fill + red border on over-budget", "Amber for 'actual' total"],
  category: ["Red soft-fill alert card", "Gentle red border", "Transaction list in card-block"],
  transactions: ["White sticky filter bar", "Filter pills: green/indigo/neutral", "Indigo 'Onchain' badge"],
  addtx: ["Green bg on amount field", "Indigo AI suggestion card", "Green checkbox tick"],
  shopping: ["Red/amber/green border tints", "Color-matched progress fills", "Status-aware pill badges"],
  shoppingdetail: ["Green bg remaining card", "Tinted total card", "Checkbox items"],
  savings: ["Green gradient hero total", "White nav on bg2", "Progress bars all green"],
  closeout: ["Step tabs in green", "Color-coded breakdown", "Surplus in amber"],
  settings: ["Green avatar gradient", "Indigo wallet badge", "Green toggle on/off state"],
  miniapp: ["Indigo Base miniapp badge", "Indigo chain badge", "No notification features", "Clean minimal layout"],
};

// ── MAIN APP ─────────────────────────────────────────────────────────────────
export default function App() {
  const [active, setActive] = useState("splash");
  const ScreenComponent = screenComponents[active] || Splash;

  return (
    <>
      <style>{css}</style>
      <div style={{ minHeight: "100vh", background: "#E8EFF0", display: "flex" }}>

        {/* ── SIDEBAR ── */}
        <div style={{ width: 224, minHeight: "100vh", background: p.white, borderRight: `1px solid ${p.border}`, padding: "24px 0", flexShrink: 0, display: "flex", flexDirection: "column", overflow: "auto", boxShadow: "2px 0 12px rgba(0,80,50,0.04)" }}>
          <div style={{ padding: "0 16px 20px", borderBottom: `1px solid ${p.border}`, marginBottom: 12 }}>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 18, color: p.green }}>PocketPal</div>
            <div style={{ fontSize: 11, color: p.muted, marginTop: 2, fontWeight: 400 }}>Light Theme · MVP Explorer</div>
          </div>

          <div style={{ padding: "0 12px", marginBottom: 8 }}>
            <div style={{ fontSize: 10, color: p.muted, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 6, padding: "0 4px" }}>Onboarding</div>
            {screens.onboarding.map(s => (
              <div key={s.id} onClick={() => setActive(s.id)} style={{ padding: "8px 10px", borderRadius: 10, cursor: "pointer", fontSize: 12, marginBottom: 2, fontWeight: active === s.id ? 600 : 400, background: active === s.id ? p.greenBg : "transparent", color: active === s.id ? p.green : p.mid, border: active === s.id ? `1px solid ${p.green}22` : "1px solid transparent", transition: "all 0.15s", fontFamily: "Outfit" }}>
                {s.label}
              </div>
            ))}
          </div>

          <div style={{ padding: "0 12px" }}>
            <div style={{ fontSize: 10, color: p.muted, fontFamily: "Syne", fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 6, padding: "0 4px" }}>Main App</div>
            {screens.main.map(s => (
              <div key={s.id} onClick={() => setActive(s.id)} style={{ padding: "8px 10px", borderRadius: 10, cursor: "pointer", fontSize: 12, marginBottom: 2, fontWeight: active === s.id ? 600 : 400, background: active === s.id ? p.greenBg : "transparent", color: active === s.id ? p.green : p.mid, border: active === s.id ? `1px solid ${p.green}22` : "1px solid transparent", transition: "all 0.15s", fontFamily: "Outfit" }}>
                {s.label}
              </div>
            ))}
          </div>
        </div>

        {/* ── CANVAS ── */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 60px", gap: 24 }}>
          <div style={{ textAlign: "center", marginBottom: 4 }}>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, color: p.text }}>{allScreens.find(s => s.id === active)?.label}</div>
            <div style={{ fontSize: 12, color: p.muted, marginTop: 4, fontWeight: 400 }}>
              {active === "miniapp" ? "Base Miniapp — manual + onchain only"
                : ["onboarding1","onboarding2","setup1","setup2","setup3"].includes(active) ? "Flutter App — Onboarding"
                : ["splash","register","login"].includes(active) ? "Flutter App — Auth"
                : "Flutter App — Main"}
            </div>
          </div>

          {/* Phone frame */}
          <div className="screen-phone">
            <StatusBar />
            <div style={{ height: "calc(100% - 44px)", overflow: "hidden", position: "relative" }}>
              <ScreenComponent />
            </div>
          </div>

          {/* Prev / Next */}
          <div style={{ display: "flex", gap: 12 }}>
            {[["← Prev", -1], ["Next →", 1]].map(([label, dir]) => {
              const idx = allScreens.findIndex(s => s.id === active);
              const target = allScreens[idx + dir];
              return (
                <button key={label} onClick={() => target && setActive(target.id)} disabled={!target} style={{ background: target ? p.white : "transparent", border: `1.5px solid ${target ? p.border : p.border}`, borderRadius: 10, padding: "8px 18px", color: target ? p.text : p.muted, fontSize: 13, cursor: target ? "pointer" : "default", fontFamily: "Syne", fontWeight: 700, boxShadow: target ? "0 2px 8px rgba(0,80,50,0.08)" : "none" }}>{label}</button>
              );
            })}
          </div>
        </div>

        {/* ── NOTES PANEL ── */}
        <div style={{ width: 240, minHeight: "100vh", background: p.white, borderLeft: `1px solid ${p.border}`, padding: "24px 16px", overflow: "auto" }}>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 13, color: p.green, marginBottom: 16 }}>Screen Notes</div>
          {notes[active] && <Note title={allScreens.find(s => s.id === active)?.label || ""} items={notes[active]} />}

          {/* Palette swatch */}
          <div style={{ marginTop: 32, borderTop: `1px solid ${p.border}`, paddingTop: 20 }}>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 11, color: p.muted, marginBottom: 12, textTransform: "uppercase", letterSpacing: "0.08em" }}>Mint Ledger Palette</div>
            {[
              [p.green, "Primary Green", "#00A86B"],
              [p.indigo, "Indigo / Base", "#4F46E5"],
              [p.amber, "Amber / Warning", "#D97706"],
              [p.red, "Danger / Over", "#DC2626"],
              [p.text, "Text Dark", "#0F1F17"],
              [p.mid, "Text Mid", "#4A6358"],
              [p.muted, "Text Muted", "#8FA89C"],
            ].map(([col, name, hex]) => (
              <div key={name} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
                <div style={{ width: 20, height: 20, borderRadius: 5, background: col, border: `1px solid ${p.border}`, flexShrink: 0 }}></div>
                <div>
                  <div style={{ fontSize: 11, fontWeight: 600, color: p.text }}>{name}</div>
                  <div style={{ fontSize: 10, color: p.muted, fontFamily: "monospace" }}>{hex}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </>
  );
}
