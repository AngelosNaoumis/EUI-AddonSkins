# EUI AddonSkins

Separat skin-addon för den bifogade Forever Companion 1.0.0-versionen (WoW Forever, Interface 16001).
Version 0.1.0 använder EllesmereUI:s officiella skinning-API. Det är en första testversion;
kod och integration har testats med en simulerad WoW-miljö, men utseende och beteende
måste verifieras i spelet.

## Installation

1. Packa upp ZIP-filen.
2. Kopiera mappen `EUIAddonSkins` till din WoW-klients `Interface/AddOns/`.
   Filen ska hamna på `Interface/AddOns/EUIAddonSkins/EUIAddonSkins.toc`.
3. Behåll Forever Companion och EllesmereUI installerade. Aktivera även **EllesmereUI Blizzard Skins+**.
   En aktuell version med `EllesmereUI.RegisterSkin` och skinning-API behövs.
4. Starta om spelet om du installerar medan det körs. Aktivera addonet i addonlistan.
5. Öppna Forever Companion som vanligt med `/fc`.

EllesmereUI väljer tema (EllesmereUI eller Modern) utifrån sina egna fönsterinställningar.
Skinnet registreras som `EUIAddonSkins` i EllesmereUI:s lista över tredjepartsskins.

## Vad som skinnas

- Huvudfönster/BiS, rotation, talanger, consumables, loot, professions, market och inställningar.
- Companion-dialoger för exempelvis specval, nyheter, guide och import/export.
- Fönsterbakgrunder, kanter, stängknappar, vanliga knappar, sökfält, dropdowns och scrollbars.
- Ikonflikar, kryssrutor och dynamiskt skapade inställningssidor/rader.
- Radbakgrunder och markeringsfärger, med EllesmereUI:s accentfärg och typsnitt.

Itemikoner, utrustningsmarkeringar, talangbilder, datainnehåll och klickfunktioner behålls.
Spelets tooltips, minimapknapp, kartmarkörer och Blizzard-auktionshuset skinnas inte av detta addon.
Dropdown-menyns popup och vanliga options-sliders använder sin befintliga utformning.

## Kommandon

`/euiskins` är huvudkommandot; `/fcskin` fungerar också som alias.

- `/euiskins` – version och status.
- `/euiskins off` – stäng av skinnet; kör sedan `/reload`.
- `/euiskins on` – aktivera skinnet; kör sedan `/reload`.
- `/euiskins refresh` – upptäck nya kontroller i kända Companion-fönster.

Du kan också stänga av tredjepartsskinning i EllesmereUI. Avstängning kräver `/reload`
eftersom redan skapade visuella element finns kvar tills UI:t laddas om.
För att avinstallera: ta bort endast `EUIAddonSkins` och starta om spelet.

## Testa i spelet

Öppna BiS och alla sidoflikar. Byt klass/spec/fas och scrolla. Öppna inställningarna
och byt sida; testa kryssrutor, sökning och dropdowns. Kontrollera att itemtooltips och
klick fungerar, och att gröna/blå utrustningskanter finns kvar. Byt EllesmereUI-tema
och accentfärg. Prova stängknapp, Escape och `/euiskins off` följt av `/reload`.

Vid problem: slå på Lua-fel med `/console scriptErrors 1`, kör `/reload` och återge felet.
Om status är inaktiv: kontrollera att Blizzard Skins+ är aktiverat, att EllesmereUI har
det officiella skinning-API:t och att tredjepartsskinning inte är avstängd.

## Tekniskt

Skinnet ändrar inga filer i Forever Companion. Det registrerar sig via
`EllesmereUI.RegisterSkin`, använder publika skin-primitiver och kopplar in sig på
`ForeverCompanionAPI`-fabriker. Returvärden och ursprungliga callbacks bevaras.
Visuella uppdateringar samlas i en enda uppskjuten passering per uppdateringsomgång;
ingen global `CreateFrame`-hook, polling eller `OnUpdate` används.
Förbjudna och skyddade frames hoppas över.

Framtida Forever Companion-versioner som byter fabriker kan behöva en anpassning.
Interface-listan omfattar klientversionerna i den granskade EllesmereUI-koden;
funktionell testning av andra Forever Companion-varianter har inte utförts.

Granskad API-dokumentation:
https://github.com/EllesmereGaming/EllesmereUI/blob/main/SKINNING_API.md

Detta är ett fristående community-addon, inte en officiell EllesmereUI-release.
