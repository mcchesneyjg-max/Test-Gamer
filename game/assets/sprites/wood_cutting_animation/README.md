# Wood cutting animation

Drop your Aseprite frame exports into this folder.

## File naming

```
wood_cutting_1.png
wood_cutting_2.png
...
wood_cutting_11.png
```

Also accepted: `wood_cutting_animation_1.png`, etc.

## Playback

1. Play frames 1–11 in order once at walk animation speed (10 fps by default)
2. After frame 11 is shown, loop frames 4–11 until chopping finishes

## Upload your PNGs

Paste files into this folder first, then:

```cmd
git add game\assets\sprites\wood_cutting_animation\*.png
git commit -m "Add wood cutting animation frames"
git push
```
