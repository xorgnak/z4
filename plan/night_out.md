# Premise
An influencer and a producer go out for the evening with the addition of multiple location ambassadors.

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
- Our producer reluctantly accepts.
- Base plans are made and agreed.

## Stage
- No pregame.
- Makeup.
- Other friends try to make futher plans - ambivelant result.

## Landing
- ideally located to be associated with the influencer.
- Outsider draw placement opprtunity.

## Float
- the inbetween location.
- should be an unexpected surprise on the way to the Last Call.
- Insider draw placement opprtunity.

## Last Call
- Should be long.
- Should be used for an outsider-interesting insider draw placement.

## Aftermath
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

