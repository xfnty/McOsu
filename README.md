![](.github/screenshot.png)

This is a fork of [McOsu][mcosu] that can save replays and is stripped of unnecessary features.

Reallistically, it is only useful for people like me whose computer can't quite handle neither stable nor
neomod and who still want to play Osu and share replays with friends.

### Differences from the original

- Saves replays (todo)
- Has Lazer-like sliders (refine)
- Has less bloat (refine)

### Compiling

The original game is supposed to be compiled with GCC and targets multiple platforms.

This fork, however, compiles with MSVC (todo) and Clang/link and targets 32-bit Windows only.

The `do.bat` script can `build` the game, `clean` output folder, `pack` the binaries for distribution and
`run` the executable. It will also check if you're running it from 32-bit VS prompt and have all the tools
installed.

[mcosu]: https://github.com/McKay42/McOsu/tree/db2add20ea291f6f3b6d022fcd4eba100a5bd161
