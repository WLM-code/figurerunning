# Figurerunning: de kaart met alle tekeningen

De app werkt ook zonder deze stappen. Pas als je ze doet, verschijnt in het deelscherm de knop
**Zet op de kaart**, en werkt `kaart.html`: de website met alle gedeelde tekeningen.
Inloggen is niet nodig.

## Eenmalig instellen (ongeveer 10 minuten)

1. Ga naar **supabase.com** en maak een gratis project (regio in West-Europa).
2. Klik op **SQL Editor → New query**. Plak de hele inhoud van `supabase.sql` en klik op **Run**.
3. Klik op **Project Settings → API Keys**. Kopieer de **anon key** (of publishable key).
   De **Project URL** staat onder **Project Settings → API** (zonder `/rest/v1/` erachter).
4. Open `config.js` en vul die twee in:
   ```js
   window.FR_CONFIG = { url: "https://jouwproject.supabase.co", key: "eyJ..." };
   ```
   Gebruik nooit de `service_role` key.
5. Zet alle bestanden in dezelfde map op GitHub Pages. De app is `index.html`, de kaart is `kaart.html`.
6. Test: teken iets in de app, tik op Delen, kies **Zet op de kaart**. Open daarna `kaart.html`.

## Update van een eerdere versie
Vervang alle bestanden, behalve `config.js` als je die al hebt ingevuld. Die laat je met rust.
Sluit de app daarna helemaal af en open hem opnieuw. Wil je het nieuwe icoon op je beginscherm?
Haal dan de oude snelkoppeling weg en zet de app opnieuw op je beginscherm.

## Wat wordt gedeeld
Alleen de getekende lijnen (kleur en plaats), de afstand en wanneer je hem plaatste.
Geen naam, geen account, geen start- of eindpunt. Wil je niet laten zien waar je begint?
Zet Pen op uit (pauze) tot je bij je startpunt bent. Dat stuk wordt dan nooit getekend.
Je haalt je tekening zelf weer weg: in het deelscherm van de app, of met de knop Weghalen op de
website. Dat werkt op het toestel en in de browser waarmee je hem plaatste.

## Beheer
- Een tekening verbergen: **Table Editor → drawings**, zet `hidden` op `true`. Of verwijder de rij.
- De website toont de 300 nieuwste tekeningen.
- Er kunnen maximaal 100 nieuwe tekeningen per 10 minuten bij (instelling in `supabase.sql`).
- Een gratis Supabase-project pauzeert na een week zonder gebruik. Je zet hem met een klik weer aan.

## App op het beginscherm
- **iPhone:** open de link in Safari, tik op Deel en kies **Zet op beginscherm**.
- **Android:** open de link in Chrome, tik op de drie puntjes en kies **App installeren**.
Een oude snelkoppeling van Krabbel of een eerdere versie moet eerst weg.

## Voorbeeld zonder Supabase
Open `kaart.html?demo` voor een kaart met voorbeeldtekeningen.
