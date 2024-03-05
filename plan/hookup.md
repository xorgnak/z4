# Premise
A primary influencer and a producer go out for the evening with the addition of multiple location ambassadors with a side quest facilitated by a secondary influencer.

## influencer
- The influencer's role is to be the focus of attention at the target locations.
- Their cosutuming should be bold and identifiable to their brand.

## producer
- The producer's role is to be the media source for the operation.
- They are responsible for the appropriate leverage of the target placements.
- Their costuming should be muted or character off-brand.

## ambassador
- The ambassador should organize the arrival and give appropriate instructions to all necessary insiders as appropriate.
- Their costuming should be on-brand, but not overly bold.

# Operation
1. Roundezvous: The set-up for the outing.
2. Stage: The initial takeoff for the outing.
3. Landing: The first target location.
4. Float: The second target location.
5. Last Call: The third target location.
6. Aftermath: The results of the outing.

## Roundezvous
- Our influencer initiates the outing.
- Our producer accepts.
- Plans are made and agreed - but not the plans we use.

## Stage
- No pregame.
- Makeup.
- Drama.

## Landing
- Should focus on a location associated with the primary influencer brand.
- Outsider draw placement opprtunity.
- Secondary influencer injects our float opprtunity.

## Float
- Introduce love interest for influencer.
- the inbetween location should the primary location for the outing.
- Insider draw placement opprtunity.

## Last Call
- should focus on the interest.
- Outsider draw opprtunity.

## Aftermath
- Include love interest.
- Should set the stage for future outings.
- Food draw placement opprtunity.

# CAST
- interest: <%= with[@cast][:interest] %>
- influencer: <%= with[@cast][:influencer] %>
- producer: <%= with[@cast][:producer] %>
- landing ambassador: <%= with[@cast][:landing] %>
- float ambassador: <%= with[@cast][:float] %>
- last call ambassador: <%= with[@cast][:lastcall] %>
- operator: <%= with[@cast][:operator] %>

# PLACEMENTS
- food draw: <%= with[@cast][:food] %>
- insider draw: <%= with[@cast][:insider] %>
- outsider draw: <%= with[@cast][:outsider] %>

# LOCATIONS
- landing: <%= with[@cast][:first] %>
- float: <%= with[@cast][:second] %>
- last call: <%= with[@cast][:third] %>
