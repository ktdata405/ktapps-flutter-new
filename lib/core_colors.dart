import 'package:flutter/material.dart';

// ── App Base Colors ────────────────────────────────────────────────────────
const ktBgDark = Color(0xFF070D18);
const ktCardBg = Color(0xFF0E1627);
const ktPrimary = Color(0xFF6366F1);
const ktSecondary = Color(0xFFA855F7);
const ktEmerald = Color(0xFF10B981);
const ktRose = Color(0xFFEF4444);
const ktCyan = Color(0xFF19E3FF);
const ktOrange = Color(0xFFFB923C);
const ktTextWhite = Colors.white;
const ktTextGray400 = Color(0xFF94A3B8);
const ktTextGray500 = Color(0xFF64748B);
const ktBorderWhite10 = Color(0x1AFFFFFF);
const ktBorderWhite5 = Color(0x0DFFFFFF);
const ktPanelBorder = Color(0x22FFFFFF);

// ── Utility Colors ────────────────────────────────────────────────────────
const ktTransparent = Colors.transparent;
const ktBlack = Colors.black;
const ktWhite = Colors.white;
const ktSuccess = Color(0xFF10B981);
const ktError = Color(0xFFEF4444);
const ktInfo = Color(0xFF3B82F6);
const ktWarning = Color(0xFFF59E0B);

// ── Extended Color Palettes (Tailwind Inspired) ───────────────────────────

// Slate
const ktSlate50 = Color(0xFFF8FAFC);
const ktSlate100 = Color(0xFFF1F5F9);
const ktSlate200 = Color(0xFFE2E8F0);
const ktSlate300 = Color(0xFFCBD5E1);
const ktSlate400 = Color(0xFF94A3B8);
const ktSlate500 = Color(0xFF64748B);
const ktSlate600 = Color(0xFF475569);
const ktSlate700 = Color(0xFF334155);
const ktSlate800 = Color(0xFF1E293B);
const ktSlate900 = Color(0xFF0F172A);
const ktSlate950 = Color(0xFF020617);

// Gray
const ktGray50 = Color(0xFFF9FAF8);
const ktGray100 = Color(0xFFF3F4F6);
const ktGray200 = Color(0xFFE5E7EB);
const ktGray300 = Color(0xFFD1D5DB);
const ktGray400 = Color(0xFF9CA3AF);
const ktGray500 = Color(0xFF6B7280);
const ktGray600 = Color(0xFF4B5563);
const ktGray700 = Color(0xFF374151);
const ktGray800 = Color(0xFF1F2937);
const ktGray900 = Color(0xFF111827);
const ktGray950 = Color(0xFF030712);

// Zinc
const ktZinc50 = Color(0xFFFAFAFA);
const ktZinc100 = Color(0xFFF4F4F5);
const ktZinc200 = Color(0xFFE4E4E7);
const ktZinc300 = Color(0xFFD4D4D8);
const ktZinc400 = Color(0xFFA1A1AA);
const ktZinc500 = Color(0xFF71717A);
const ktZinc600 = Color(0xFF52525B);
const ktZinc700 = Color(0xFF3F3F46);
const ktZinc800 = Color(0xFF27272A);
const ktZinc900 = Color(0xFF18181B);
const ktZinc950 = Color(0xFF09090B);

// Neutral
const ktNeutral50 = Color(0xFFFAFAFA);
const ktNeutral100 = Color(0xFFF5F5F5);
const ktNeutral200 = Color(0xFFE5E5E5);
const ktNeutral300 = Color(0xFFD4D4D4);
const ktNeutral400 = Color(0xFFA3A3A3);
const ktNeutral500 = Color(0xFF737373);
const ktNeutral600 = Color(0xFF525252);
const ktNeutral700 = Color(0xFF404040);
const ktNeutral800 = Color(0xFF262626);
const ktNeutral900 = Color(0xFF171717);
const ktNeutral950 = Color(0xFF0A0A0A);

// Stone
const ktStone50 = Color(0xFFFAFAF9);
const ktStone100 = Color(0xFFF5F5F4);
const ktStone200 = Color(0xFFE7E5E4);
const ktStone300 = Color(0xFFD6D3D1);
const ktStone400 = Color(0xFFA8A29E);
const ktStone500 = Color(0xFF78716C);
const ktStone600 = Color(0xFF57534E);
const ktStone700 = Color(0xFF44403C);
const ktStone800 = Color(0xFF292524);
const ktStone900 = Color(0xFF1C1917);
const ktStone950 = Color(0xFF0C0A09);

// Red
const ktRed50 = Color(0xFFFEF2F2);
const ktRed100 = Color(0xFFFEE2E2);
const ktRed200 = Color(0xFFFECACA);
const ktRed300 = Color(0xFFFCA5A5);
const ktRed400 = Color(0xFFF87171);
const ktRed500 = Color(0xFFEF4444);
const ktRed600 = Color(0xFFDC2626);
const ktRed700 = Color(0xFFB91C1C);
const ktRed800 = Color(0xFF991B1B);
const ktRed900 = Color(0xFF7F1D1D);
const ktRed950 = Color(0xFF450A0A);

// Orange
const ktOrange50 = Color(0xFFFFF7ED);
const ktOrange100 = Color(0xFFFFEDD5);
const ktOrange200 = Color(0xFFFED7AA);
const ktOrange300 = Color(0xFFFDBA74);
const ktOrange400 = Color(0xFFFB923C);
const ktOrange500 = Color(0xFFF97316);
const ktOrange600 = Color(0xFFEA580C);
const ktOrange700 = Color(0xFFC2410C);
const ktOrange800 = Color(0xFF9A3412);
const ktOrange900 = Color(0xFF7C2D12);
const ktOrange950 = Color(0xFF431407);

// Amber
const ktAmber50 = Color(0xFFFFFBEB);
const ktAmber100 = Color(0xFFFEF3C7);
const ktAmber200 = Color(0xFFFDE68A);
const ktAmber300 = Color(0xFFFCD34D);
const ktAmber400 = Color(0xFFFBBF24);
const ktAmber500 = Color(0xFFF59E0B);
const ktAmber600 = Color(0xFFD97706);
const ktAmber700 = Color(0xFFB45309);
const ktAmber800 = Color(0xFF92400E);
const ktAmber900 = Color(0xFF78350F);
const ktAmber950 = Color(0xFF451A03);

// Yellow
const ktYellow50 = Color(0xFFFEFCE8);
const ktYellow100 = Color(0xFFFEF9C3);
const ktYellow200 = Color(0xFFFEF08A);
const ktYellow300 = Color(0xFFFDE047);
const ktYellow400 = Color(0xFFFACC15);
const ktYellow500 = Color(0xFFEAB308);
const ktYellow600 = Color(0xFFCA8A04);
const ktYellow700 = Color(0xFFA16207);
const ktYellow800 = Color(0xFF854D0E);
const ktYellow900 = Color(0xFF713F12);
const ktYellow950 = Color(0xFF422006);

// Lime
const ktLime50 = Color(0xFFF7FEE7);
const ktLime100 = Color(0xFFECFCCB);
const ktLime200 = Color(0xFFD9F99D);
const ktLime300 = Color(0xFFBEF264);
const ktLime400 = Color(0xFFA3E635);
const ktLime500 = Color(0xFF84CC16);
const ktLime600 = Color(0xFF65A30D);
const ktLime700 = Color(0xFF4D7C0F);
const ktLime800 = Color(0xFF3F6212);
const ktLime900 = Color(0xFF365314);
const ktLime950 = Color(0xFF1A2E05);

// Green
const ktGreen50 = Color(0xFFF0FDF4);
const ktGreen100 = Color(0xFFDCFCE7);
const ktGreen200 = Color(0xFFBBF7D0);
const ktGreen300 = Color(0xFF86EFAC);
const ktGreen400 = Color(0xFF4ADE80);
const ktGreen500 = Color(0xFF22C55E);
const ktGreen600 = Color(0xFF16A34A);
const ktGreen700 = Color(0xFF15803D);
const ktGreen800 = Color(0xFF166534);
const ktGreen900 = Color(0xFF14532D);
const ktGreen950 = Color(0xFF052E16);

// Emerald
const ktEmerald50 = Color(0xFFECFDF5);
const ktEmerald100 = Color(0xFFD1FAE5);
const ktEmerald200 = Color(0xFFA7F3D0);
const ktEmerald300 = Color(0xFF6EE7B7);
const ktEmerald400 = Color(0xFF34D399);
const ktEmerald500 = Color(0xFF10B981);
const ktEmerald600 = Color(0xFF059669);
const ktEmerald700 = Color(0xFF047857);
const ktEmerald800 = Color(0xFF065F46);
const ktEmerald900 = Color(0xFF064E3B);
const ktEmerald950 = Color(0xFF022C22);

// Teal
const ktTeal50 = Color(0xFFF0FDFA);
const ktTeal100 = Color(0xFFCCFBF1);
const ktTeal200 = Color(0xFF99F6E4);
const ktTeal300 = Color(0xFF5EEAD4);
const ktTeal400 = Color(0xFF2DD4BF);
const ktTeal500 = Color(0xFF14B8A6);
const ktTeal600 = Color(0xFF0D9488);
const ktTeal700 = Color(0xFF0F766E);
const ktTeal800 = Color(0xFF115E59);
const ktTeal900 = Color(0xFF134E4A);
const ktTeal950 = Color(0xFF042F2E);

// Cyan
const ktCyan50 = Color(0xFFECFEFF);
const ktCyan100 = Color(0xFFCFFAFE);
const ktCyan200 = Color(0xFFA5F3FC);
const ktCyan300 = Color(0xFF67E8F9);
const ktCyan400 = Color(0xFF22D3EE);
const ktCyan500 = Color(0xFF06B6D4);
const ktCyan600 = Color(0xFF0891B2);
const ktCyan700 = Color(0xFF0E7490);
const ktCyan800 = Color(0xFF155E75);
const ktCyan900 = Color(0xFF164E63);
const ktCyan950 = Color(0xFF083344);

// Sky
const ktSky50 = Color(0xFFF0F9FF);
const ktSky100 = Color(0xFFE0F2FE);
const ktSky200 = Color(0xFFBAE6FD);
const ktSky300 = Color(0xFF7DD3FC);
const ktSky400 = Color(0xFF38BDF8);
const ktSky500 = Color(0xFF0EA5E9);
const ktSky600 = Color(0xFF0284C7);
const ktSky700 = Color(0xFF0369A1);
const ktSky800 = Color(0xFF075985);
const ktSky900 = Color(0xFF0C4A6E);
const ktSky950 = Color(0xFF082F49);

// Blue
const ktBlue50 = Color(0xFFEFF6FF);
const ktBlue100 = Color(0xFFDBEAFE);
const ktBlue200 = Color(0xFFBFDBFE);
const ktBlue300 = Color(0xFF93C5FD);
const ktBlue400 = Color(0xFF60A5FA);
const ktBlue500 = Color(0xFF3B82F6);
const ktBlue600 = Color(0xFF2563EB);
const ktBlue700 = Color(0xFF1D4ED8);
const ktBlue800 = Color(0xFF1E40AF);
const ktBlue900 = Color(0xFF1E3A8A);
const ktBlue950 = Color(0xFF172554);

// Indigo
const ktIndigo50 = Color(0xFFEEF2FF);
const ktIndigo100 = Color(0xFFE0E7FF);
const ktIndigo200 = Color(0xFFC7D2FE);
const ktIndigo300 = Color(0xFFA5B4FC);
const ktIndigo400 = Color(0xFF818CF8);
const ktIndigo500 = Color(0xFF6366F1);
const ktIndigo600 = Color(0xFF4F46E5);
const ktIndigo700 = Color(0xFF4338CA);
const ktIndigo800 = Color(0xFF3730A3);
const ktIndigo900 = Color(0xFF312E81);
const ktIndigo950 = Color(0xFF1E1B4B);

// Violet
const ktViolet50 = Color(0xFFF5F3FF);
const ktViolet100 = Color(0xFFEDE9FE);
const ktViolet200 = Color(0xFFDDD6FE);
const ktViolet300 = Color(0xFFC4B5FD);
const ktViolet400 = Color(0xFFA78BFA);
const ktViolet500 = Color(0xFF8B5CF6);
const ktViolet600 = Color(0xFF7C3AED);
const ktViolet700 = Color(0xFF6D28D9);
const ktViolet800 = Color(0xFF5B21B6);
const ktViolet900 = Color(0xFF4C1D95);
const ktViolet950 = Color(0xFF2E1065);

// Purple
const ktPurple50 = Color(0xFFFAF5FF);
const ktPurple100 = Color(0xFFF3E8FF);
const ktPurple200 = Color(0xFFE9D5FF);
const ktPurple300 = Color(0xFFD8B4FE);
const ktPurple400 = Color(0xFFC084FC);
const ktPurple500 = Color(0xFFA855F7);
const ktPurple600 = Color(0xFF9333EA);
const ktPurple700 = Color(0xFF7E22CE);
const ktPurple800 = Color(0xFF6B21A8);
const ktPurple900 = Color(0xFF581C87);
const ktPurple950 = Color(0xFF3B0764);

// Fuchsia
const ktFuchsia50 = Color(0xFFFDF4FF);
const ktFuchsia100 = Color(0xFFFAE8FF);
const ktFuchsia200 = Color(0xFFF5D0FE);
const ktFuchsia300 = Color(0xFFF0ABFC);
const ktFuchsia400 = Color(0xFFE879F9);
const ktFuchsia500 = Color(0xFFD946EF);
const ktFuchsia600 = Color(0xFFC026D3);
const ktFuchsia700 = Color(0xFFA21CAF);
const ktFuchsia800 = Color(0xFF86198F);
const ktFuchsia900 = Color(0xFF701A75);
const ktFuchsia950 = Color(0xFF4A044E);

// Pink
const ktPink50 = Color(0xFFFDF2F8);
const ktPink100 = Color(0xFFFCE7F3);
const ktPink200 = Color(0xFFFBCFE8);
const ktPink300 = Color(0xFFF9A8D4);
const ktPink400 = Color(0xFFF472B6);
const ktPink500 = Color(0xFFEC4899);
const ktPink600 = Color(0xFFDB2777);
const ktPink700 = Color(0xFFBE185D);
const ktPink800 = Color(0xFF9D174D);
const ktPink900 = Color(0xFF831843);
const ktPink950 = Color(0xFF500724);

// Rose
const ktRose50 = Color(0xFFFFF1F2);
const ktRose100 = Color(0xFFFFE4E6);
const ktRose200 = Color(0xFFFECDD3);
const ktRose300 = Color(0xFFFDA4AF);
const ktRose400 = Color(0xFFFB7185);
const ktRose500 = Color(0xFFF43F5E);
const ktRose600 = Color(0xFFE11D48);
const ktRose700 = Color(0xFFBE123C);
const ktRose800 = Color(0xFF9F1239);
const ktRose900 = Color(0xFF881337);
const ktRose950 = Color(0xFF4C0519);

// ── Specialized App Variations ───────────────────────────────────────────

// Deep Dark Variations
const ktDeepBg = Color(0xFF020408);
const ktSurfaceDark = Color(0xFF0F172A);
const ktSurfaceDarker = Color(0xFF0B1222);
const ktMidnight = Color(0xFF010203);

// Vibrant Accents
const ktElectricCyan = Color(0xFF00E5FF);
const ktVibrantPurple = Color(0xFFBF5AF2);
const ktNeonGreen = Color(0xFF32D74B);
const ktNeonRed = Color(0xFFFF3B30);
const ktNeonBlue = Color(0xFF007AFF);
const ktNeonYellow = Color(0xFFFFD60A);

// Glassmorphism Helpers
const ktGlassWhite = Color(0x1FFFFFFF);
const ktGlassBlack = Color(0x4D000000);
const ktGlassBorder = Color(0x33FFFFFF);

// ── Legacy Aliases & Specialized UI Colors ───────────────────────────────
const ktBlue = ktBlue500;
const ktIndigo = ktIndigo500;
const ktSlate = ktSlate500;
const ktAmber = ktAmber500;
const ktPink = ktPink500;
const ktTeal = ktTeal500;
const ktViolet = ktViolet500;

const ktDarkBlue = Color(0xFF0C111C);
const ktPrimaryAccent = Color(0xFF6A5DF6);
const ktDarkBlueHeader = Color(0xFF0B1322);
const ktCyanLight = Color(0xFF10C9E9);
const ktCyanDark = Color(0xFF0B89B6);
const ktNavyLight = Color(0xFF12284F);
const ktNavyDark = Color(0xFF11306B);
const ktBlueBorder = Color(0x334A7CFF);
const ktPurpleLight = ktPurple400;
const ktGreenBright = ktGreen400;
const ktPinkLight = ktPink300;
const ktSlateGray = ktSlate400;
const ktBlueSave1 = Color(0xFF3F55E4);
const ktBlueSave2 = Color(0xFF1FC8C0);

const ktDarkBg = Color(0xFF030305);
const ktDarkIndigo = ktIndigo950;
const ktDarkCardBg = Color(0xFF151A25);
const ktSlateBg = ktSlate800;

const ktLightScaffoldBg = Color(0xFFF0F2F5);
const ktWhite80 = Color(0xCCFFFFFF);
const ktDarkText = Color(0xFF1A202C);
const ktDarkSurface = Color(0x990F172A);

const ktInk = Color(0xFF1F222A);
const ktTealPanel = Color(0xFF1C4A57);
const ktPanelBorderReport = Color(0x3DB2F5EA);

// Denomination Specific Colors
const ktDenom500 = ktAmber400;
const ktDenom200 = ktEmerald400;
const ktDenom100 = ktBlue400;
const ktDenom50 = ktOrange400;
const ktDenom20 = ktRose400;
const ktDenom10 = Color(0xFF86EFAC); // Custom light green
const ktDenom5 = Color(0xFFD4D4D4);
const ktDenom2 = ktAmber300;
const ktDenomOther = Color(0xFFA8A29E);

// Opacity Overlays
const ktSuccessBg = Color(0x1A10B981);
const ktErrorBg = Color(0x1AEF4444);
const ktInfoBg = Color(0x1A3B82F6);
const ktWarningBg = Color(0x1AF59E0B);

const ktWhite70 = Colors.white70;
const ktWhite60 = Colors.white60;
const ktWhite54 = Colors.white54;
const ktWhite38 = Colors.white38;
const ktWhite30 = Colors.white30;
const ktWhite24 = Colors.white24;
const ktWhite12 = Colors.white12;
const ktWhite10 = Colors.white10;

const ktBlack87 = Colors.black87;
const ktBlack54 = Colors.black54;
const ktBlack45 = Colors.black45;
const ktBlack38 = Colors.black38;
const ktBlack26 = Colors.black26;
const ktBlack12 = Colors.black12;
