# Current 50 Curse VFX mapping

Revision SHA256: `6b8b472beb57af366e6d2ecbc899e1ca80c7c727dace0408f7191bff8e1d3b71`

Static coverage: 50 models / 50 profiles / 50 primary hooks / 27 named hooks. Studio visibility and native execution remain separate checks.

Desktop: at most 20 near objects and 2 lights. Mobile: at most 12 near objects, no lights. Tick/heartbeat multipliers never exceed 1.6; largest configured instantaneous rate remains 5 particles/second.

| Curse | Particle concept | Motion | Focal selection |
|---|---|---|---|
| Candle Wisp | Controlled blue ghost flame | flicker | Exposed authored focal point |
| Grave Hopper | Moss spores from the grave shell | drift | Authored focal point |
| Grave Key | Cold glint on the key ring | pulse | Authored focal point |
| Mourning Ribbon | Seam whispers along mourning cloth | sway | Authored focal point |
| Wilted Sprout | Last drifting pollen | sway | Exposed authored focal point |
| Ink Imp | Slow black ink drops | pulse | Authored focal point |
| Lost Locket | A memory inside the empty portrait | pulse | Authored focal point |
| Ashen Book | Ash from the burnt page | sway | Authored focal point |
| Lantern Lurker | Trapped green lantern light | flicker | Authored focal point |
| Hourglass Hound | Sand falling through the narrow waist | still | Authored focal point |
| Nail Beetle | Rust dust between coffin nails | pulse | Authored focal point |
| Pale Guest | Breath escaping the crooked portrait | sway | Authored focal point |
| Cold Teacup | Curved cold tea steam | sway | Authored focal point |
| Coin Crawler | Brief funeral coin glints | pulse | Authored focal point |
| Umbrella Wraith | Faint rain under the torn canopy | sway | Authored focal point |
| Marrow Dice | Cyan spirits in the carved pips | orbit | Exposed authored focal point |
| Veil Mourner | Pale breath under a black veil | sway | Authored focal point |
| Grave Compass | A wandering cold compass bearing | orbit | Authored focal point |
| Hollow Violin | Three cold string resonances | strings | Authored focal point |
| Chime Triplets | Staggered bell chimes | chime | leftBell, middleBell, rightBell |
| Thimble Spider | Silver thread caught on the thimble | sway | Exposed authored focal point |
| Music Box Dancer | Tiny music box notes and turn | orbit | Authored focal point |
| Raven Quill | Ink flecks beneath the silver nib | sway | Authored focal point |
| Sorrow Chalice | One slow spectral tear | pulse | Exposed authored focal point |
| Pale Gramophone | Horn echoes over the turning record | gramophone | hornMouth, turntable |
| Thorn Reliquary | Dim spores trapped within the urn | orbit | Authored focal point |
| Anchor Crab | Salt spray between anchor claws | drift | Authored focal point |
| Sundial Sentinel | A warm moving sundial edge | orbit | Authored focal point |
| Sleepwalker Shoes | Alternating cold footprints | step | leftCuff, rightCuff |
| Night Harp | Golden strings on an indigo beast | strings | Authored focal point |
| Thorn Cathedral | Blood red rose window embers | pulse | Authored focal point |
| Phantom Marionette | Ivory control thread shivers | strings | Authored focal point |
| Blood Moon Rose | Garnet pollen inside glass petals | orbit | Authored focal point |
| Judgement Scales | Unequal gold soul weights | scales | leftPan, rightPan |
| Clockwork Raven | A measured brass clock pulse | tick | Authored focal point |
| Eclipse Stag | Jade breath and ivory antler motes | sway | Authored focal point |
| Endless Library | Lost paper and quiet page dust | sway | Authored focal point |
| Sunken Crown | Water rising around coral ivory | orbit | Authored focal point |
| Silent Choir | Three solemn pale harmonics | choir | leftHead, middleHead, rightHead |
| Cathedral Heart | Slow ivory heart beat | heartbeat | Authored focal point |
| Plague Monarch | Verdigris royal spores | orbit | Authored focal point |
| Hollow Throne | Breath around the empty king | pulse | Authored focal point |
| Worldroot | Jade seed and drifting root spores | heartbeat | Authored focal point |
| The Undertow | A circling dark turquoise undertow | vortex | Authored focal point |
| The Last Funeral | Ivory funeral petals and incense | sway | Authored focal point |
| Nameless Door | A jade threshold bending inward | vortex | Authored focal point |
| Crown of Silence | Interrupted ivory crown waves | silence | Authored focal point |
| The First Grave | Ancient green seams and grave dust | heartbeat | Authored focal point |
| The Unwritten | Erasing white flecks by a red seam | erase | Authored focal point |
| The Last Star | White star light inside an open rib cage | star | Authored focal point |

## Verification

All 50 editable blends and individual FBXs retain their exact byte hashes. Source BVH checks cover corrected focal positions and complete local paths for Choir, Scales and Gramophone. Maximum static hook exposure outside mesh bounds is 0.180 studs, within the explicit 0.25-stud presentation allowance.

For complete fixture observations, sample heartbeat for at least 3.2 seconds, Choir for 3.1 seconds, and Gramophone for 4.1 seconds. Silence and erasure stop creating particles; existing particles finish their short lifetime.
