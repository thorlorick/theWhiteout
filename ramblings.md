# THUS IT BEGINS
we are starting a new project. A souslike grammar game for french. It's going to be 2D top down and we are building it in Godot. I have no clue what I'm doing!!!

# Feb 14, 2026
Still no clue, but I'm able to build a scene with layers and collisions and even move a guy around a screen...animated!!!
that's right!!!

# Feb 17, 2026
Still no clue, and at times I feel like I know less than yesterday....there is a tremendous amound of paralysis by over load in this world. There are so many little things to take care of, for every little scene, it is REALLY hard to try and even get started...where do you begin when faced with a mountain a mini chaos...???? The answer is, it doesn't matter...just don't sit still....always moving forward!!!!

# Feb 19, 2026
I'm getting the hang of a few things, but nothing concrete yet. I've got a bunch of little bits and bobs but I need to get them all together into a whole. One simple level...right!!

# Feb 21, 2026
Learning to use animation player. It's ok, but a bit finicky. I don't really know how to use it so I often delete things.
I do have a bunch of animations now though, and understand how and where to get them...now to see if we can call them. 

# Feb 27, 2026
We've hit our first philosiphical issue...state machines and behaviour trees. Small game yes, but does that mean the enemy shouldn't have some personality...not sure. Am I skilled enough to build it...definitely not. BUT, it does make a bit more sense when thinking about how to think about the game....turtles upon turtles!!!!!

# March 2, 2026
We've discoverd GOAP -- Goal Oriented Action Plannning -- AI for the video games. It allows for costs attached to desires....looks really cool.

# March 7, 2026
GOAP is the GOAT!!!! jokes aside...it's truly awesome. I now have a fully animated goblin guard walking around a region constantly struggling with whether to patrol or go home...it's really cool. Now we have to add some more behaviours...this is so much fun!!!!

# March 12, 2026
GOAP has lived up to the hype. I have gone hardcore component mode, strict rule adherence with no "minor violations". I have a standard guard that seems to fight different urges in order to decide what to do. Next, we are going to try to figure out costs and how to use them for personality tuning. Wish me luck.

# March 16, 2026
I'm starting to get a handle on some basics but there's still a ton I don't understand. 
how am I going I make combat fun with only 1 animation??

# March 17, 2026
I thought I had a really nice spritesheet maker, but it didn't work so well. I still see some possibilities with it, but the sheets don't translate very well to the animation player..LPC, if you are listening..your site is awesome, but I need help!!! Other than that. I'm going to start to build with the sprite sheets I have and try to muck about with LPC when I get the time. 

# March 21, 2026
I just started the animation tree portion of the enemy design (i actually thought I might start building a level...ahhahahahah) and it completely changed everything about everything. I'm still a fanatical componentist...compositonalists...??? i still love components, but i've come to believe that there has to be a middle ground...i mean, jesus, why shouldn't movement know about speed...it's moving for god's sake. Anyways, as you can probably tell from my frustration, i'm at a crucial moment here. BUT, the urge system is holding and I'm going to keep using that system to "replan" whenever there is a need to do so.
So much still to learn and do...the good news, I'm still completely loving it!!!!

# March 22, 2026
This is where Claude believes we are right now:
"I'm building a 2D guard enemy in Godot using a component-based architecture. I'm one month into game development. My guard has: UrgeComponent (four drives — comfort, duty, curiosity, aggression — shaped by a PersonalityResource), PlannerComponent (GOAP-style, picks best goal and action, has inertia to prevent flip-flopping), WorldState (blackboard of facts), GoalsComponent, ActionsComponent, SpeedComponent, AIMoveComponent, EnemyAnimationComponent, AttackComponent, VisionComponent, ChaseComponent, PatrolComponent, SearchComponent, HealthComponent, and a GuardAgent that orchestrates everything.
We recently refactored to add a ReflexComponent — a plain class (not a Node) that handles immediate pre-deliberate interrupts. It owns no components and touches nothing directly. It only emits signals. The agent wires those signals and does the shouting at components. The rule is strict — signals always, no component talks directly to another.
The architecture has three distinct layers: Reflex (immediate interrupts, no deliberation), Urge (emotional landscape, builds and decays over time shaped by personality), and Planner (deliberate decisions, reads the urge landscape via goals and world state).
The agent's job is hear and shout — update world state, tell urges, tell reflex, then relay reflex signals to components. It makes no decisions of its own.
The system is working and producing believable emergent behavior — a guard who patrols, spots, chases, attacks, searches, and decides to go home when comfort wins over curiosity. No combat system, health bars, or knockback yet — those are next. Knockback should slot in cleanly as a reflex interrupt that jolts the urge system emotionally based on personality, then lets the planner decide what happens next."

ALRIGHT, ALRIGHT, ALRIGHT.....not bad....!!

# March 23, 2026
It's been a busy day...a day???? oh man....anyways. The reflex refactor, as it's coming to be known, was a mess. Luckily our component structure held firm and we contained the mess, but oh what a mess. I think we are close, but no testing has been done,....and still no combat system to speak of. We got rid of UE from the code, so everything says target this and target that...much more boring, but I understand the reasoning behind it.
I also want/need to develop some more goals and actions for more advanced AI enemies. right now they just go off their urges...very, un-intelligent...but with a few more actions and possibly a few more urges, then we will have a nice system with costs and goals, and decisions. BUT, for now...combat!!!!!

# March 25, 2026
Refactor has been hell!!!!! The whole thing just completely shut down. I've spent the last two days rebuilding everything, so it's been a worthwhile experience. I've bulked up the vision a bit and added some debuggin to it so it's easier to see. I really need to get combat up and running.

# March 29, 2026
Shockingly, refactor just finished...it was awful...scratch that, I don't know if it's done, but I think I understand the code better now. There were signals being sent out to the void, urge systems completely abandoned...we really need to watch when the code switches that all the old code, the necessary code, get's put back. Thank god for the limited version system I have going on. Time for combat. This is goign to be tough. BUT after this, I think I'm close to level design.....which means playing with the AI more!!!!! -- what other actions can I give him!!!!!

# March 30, 2026
And somehow, just like that...player flew across the screen!!!! Honestly...it took WAY too long to figure out hit and hurtboxes...still not sure if I fully understand what's going on. BUT it works. and then we threw in some knockback for fun...oh man...just completely off the screen!! Too funny. So now, we are talking about poise...ahhahahah!!!!!
Seriously though, we might do some sort of weight for the guards...another variable....possibly another urge. Self-esteem!!!! hahaha - a guard who loves his body might fight harder....ahhahahha. Never mind.

# April 2, 2026
As if by some sort of cosmic joke (yes, I see the date!!) the whole system is broken. I don't think it's from the refactor, but rather from trying to jam a bunch of components together and then praying they will work...they didn't work!!! So, it's back to the drawing board, but with way better drawings!! I'm going to add a few more actions and really flesh out the urge and goal system to try to make the AI solid. There needs to some reflex interrupts, and I've even considering a full combat system to over-ride everything..but I'm not sure about that one. For now. we have to get the urge and actions working...then combat. Once more into the breach...

# April 3, 2026 
We had a good session and completely reworked the urges and the goals to add some more variety. Not everything is wired up yet, but there is definitely better behaviour now. I have to fix vision, and combat is still a mess. At some point we have to dive deep into the animation player and start wiring in sounds and effects...no clue about that side of things yet. Get the AI build, get the starting room built, build out from there. That's the plan.

# April 7, 2026
Oh my god.........this damn system is going to be the death of me. Vision keeps freaking out and the guard can't "see" the target right in front of him....no clue why, so now I have to bring back old school methods -- personal space!!! Actually, we are revamping the combat system (again!!!) as a result of this "glitch". The plan now is to implement a combat meter (already had one in vision) inside a combat component. The meter will fill through vision, personal space breaching, urges...whatever we can think of to complicate this even more!!! BUT, once the meter is filled, then combat begins. ONE ENTRY!! Once we are in combat, we can only exit through death or the player leaving our personal space. Then the meter unclamps, and the guard can figure out what to do...I really need to stop the flip flopping that freaks the guard out. Already, I'm questioning this system. It could work in theory, if we can have the meter fluctuate without freaking out...it needs to move up and down gracefully. --- maybe it's as simple as hits landed vs hits received....maybe?!?
