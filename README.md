<p align="center">
  <img width="640" src=".github/screenshot.png">
</p>

This is a fork of [McOsu][mcosu] with a couple of changes to save replays.

Reallistically, it is only useful for people like me whose computer can't quite handle neither stable nor
[neomod][neomod] and who still want to play Osu and share replays with friends.

Currently it saves all replays under `replays/` folder.

**Download the latest build [here][dl].**

For a more advanced fork see [neosu][neosu].

### Compiling

The original game is supposed to be compiled with GCC and targets multiple platforms.

This fork, however, compiles with Clang/link and targets 32-bit Windows only.

```bat
cmake --preset release
cmake --build --preset release
start "" /b /wait /d bin bin\release\McEngine.exe
tar -acf McOsu-windows-x86.zip -C bin\release *
```

[mcosu]: https://github.com/McKay42/McOsu/tree/db2add20ea291f6f3b6d022fcd4eba100a5bd161
[neomod]: https://neomod.net
[neosu]: https://git.kiwec.net/kiwec/neosu
[dl]: https://github.com/xfnty/McOsu/releases/latest
