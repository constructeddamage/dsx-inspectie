# DSX Inspectie

## Overzicht
Deze resource is bedoeld voor een FiveM server die ESX en OX gebruikt als framework. Het idee is dat spelers verschillende inspectietaken krijgen, zoals het repareren van een zendmast, vervangen van zekeringen, meten van de waterkwaliteit of het kalibreren van een satellietschotel. Je gaat naar de klus met je dienstvoertuig. Tijdens de uitvoeren van de taken krijg je opdrachten die je moet uitvoeren om zo uiteindelijk een kleine beloning te krijgen. Daarna krijg je een nieuwe klus.

## Concept en Denkwijze
Ik maak scripts die duidelijk en overzichtelijk zijn. Daarom zijn dingen ook opgedeeld in categorieen zoals variables, functions en main script.

1. **Taken duidelijk maken**  
   Elke taak heeft een beschrijving, locatie en beloning. Spelers krijgen meerdere notificaties om zo dingen te verduidelijken en vervolgens steeds nieuwe taken geven.

2. **Interactieve gameplay**  
   - Skillchecks voor moeilijkere taken, zodat er uitdaging is.  
   - Progress bars en scenario’s om het leuk te houden.  
   - Input voor sommige taken, zoals het analyseren van waterkwaliteit met PH waardes en temperaturen.

3. **Beveiliging**  
   - Server checkt altijd of een speler dichtbij de taak is voordat deze voltooid kan worden.  
   - Tokens voorkomen dat spelers taken kunnen afronden die ze niet hebben gekregen.  
   - Cooldowns voorkomen dat spelers taken te snel achter elkaar doen.

4. **Gebruiksvriendelijk voor de speler**  
   - Meerdere blips, waypoints en notificaties voor de speler om het duidelijk te maken wat de bedoeling is.  
   - ox_target zorgt voor eenvoudige manier van interactie met het starten van een dienst of het uitvoeren van een taak.  
   - Voertuigen kunnen eenvoudig gespawned en weggezet worden.

5. **Makkelijk uit te breiden**  
   - Nieuwe taken toevoegen kan door simpelweg een item toe te voegen aan `Config.Tasks` en vervolgens een functie er aan te koppelen in de client.lua.  
   - Locaties, beloningen en labels zijn allemaal aanpasbaar in shared/config.lua.

## Technische uitleg
- **Client** (`client/main.lua`):  
- Maakt de npc's & blips.  
- Voert de taken uit voor de speler inclusief progress bars, skillchecks en input dialogs (waterkwaliteit).  
- Verwerkt het starten en annuleren van taken.

- **Server** (`server/main.lua`):  
- Houdt bij welke speler welke taak heeft.  
- Spawn en verwijder voertuigen.  
- Strakke beveiliging: tokens, locatie en cooldowns.  
- Geeft beloning en start automatisch een nieuwe taak als de vorige voltooid is.

- **Config** (`shared/config.lua`):  
- Alle instellingen zoals jobnaam, locaties, beloningen en taken.  
- Gemakkelijk aan te passen voor nieuwe taken of locaties.

Er wordt geen verbinding gemaakt met de database omdat dit simpelweg niet nodig is. Het enigste wat er moet gebeuren is de job toevoegen in `jobs` en `job_grades`. Zie hiervoor het bijgevoegde SQL bestand. Als dat gebeurd is word de baan automatisch in het joblisting systeem van ESX gezet en dan kunnen spelers beginnen!

## Toekomstige verbeteringen
- Meer variatie in skillchecks.  
- Extra taken met verschillende moeilijkheidsgraden.  
- Eventueel een leaderboard voor productiviteit of beloningen.
- Hogere beloningen naarmate je vordert in de job.