# Cumulative Retention

## Ziel

Ziel dieser Analyse ist es zu verstehen, wie viele Kunden nach ihrer ersten Bestellung mindestens einmal zurückkehren.

Im Gegensatz zur klassischen Retention wird nicht betrachtet, ob ein Kunde in einem bestimmten Monat aktiv ist, sondern:

> ob ein Kunde bis zu einem bestimmten Zeitpunkt mindestens einmal erneut gekauft hat

---

## Datengrundlage

Verwendet werden relevante CSV-Dateien aus dem Olist E-Commerce Datensatz, insbesondere:

- Bestellungen  
- Kunden  

Berücksichtigt werden ausschließlich Bestellungen mit:

- `order_status = 'delivered'`

Begründung:

Nur ausgelieferte Bestellungen stellen tatsächlich abgeschlossene Käufe dar.  
Andere Status (z. B. „canceled“) würden das Ergebnis verfälschen.

Analyseebene:

- `customer_unique_id` (repräsentiert den tatsächlichen Kunden über mehrere Bestellungen hinweg)

---

## Analysefenster

Die Analyse beschränkt sich auf Kohorten im Zeitraum:

- Januar 2017 bis September 2017

Beobachtungsdauer:

- 9 Monate (Month 0 bis Month 8)

Begründung:

Der Datensatz ist zeitlich begrenzt.  
Spätere Kohorten könnten nicht über denselben Zeitraum beobachtet werden.

Um eine vergleichbare Auswertung zu gewährleisten, wird daher ein einheitliches Beobachtungsfenster verwendet.

---

## Methodik

### Kohortendefinition und Zeitstruktur

Jeder Kunde wird anhand seines ersten Kaufs einer Kohorte zugeordnet:

- `cohort_month = Monat der ersten Bestellung`

Für jede Bestellung wird der Abstand zur ersten Bestellung berechnet:

- `month_number = Monate seit erster Bestellung`

---