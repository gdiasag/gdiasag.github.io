---
layout: file
title: gustavo's terminal
permalink: /
---

# Preface

On this website, you will find everything related to the technical aspects of my life --- a large enough part of it to deserve a dedicated place on the Internet.

Among other stuff, you can browse through [projects](#code) I've worked on or that are in current development, things I've [written](#notes), [talks](#slides) I've presented, [books](#books) I've read or will read in the future, [themes](#themes) I've used, and [links](#elsewhere) to places you can find me on other parts of the Web.

## About Me

...

## Code

...

## Notes

...

## Slides

Content indexed in [slides/](slides/) refers to the more significant talks I've presented, either by myself or accompanied by friends and/or colleagues. Collaborative presentations include a full list of contributors and where they can be found at the beginning or end of a document.

## Books

The [books/](books/) directory lists my personal catalog, physical and digital, along with works that caught my attention and that I have yet to read. Recurring topics you'll encounter are:

- Databases
- Compilers
- Operating systems
- Type theory
- Foundational computer science
- Low-level systems software.

## Themes

Within [themes/](themes/) you will find a listing of every text editor/terminal colorscheme I've used so far. There you can toggle the theme of this very website, or, if you prefer to do it via command mode, just do a `:colorscheme` and select one to your liking.

Themes also affect syntax highlighting on code blocks:

```zig
pub fn fchmod(fd: fd_t, mode: mode_t) FChmodError!void {
    if (!fs.has_executable_bit) @compileError("unsupported by target OS");
    while (true) {
        const res = system.fchmod(fd, mode);
        switch (errno(res)) {
            .SUCCESS => return,
            .INTR => continue,
            .BADF => unreachable,
            .FAULT => unreachable,
            .INVAL => unreachable,
            .ACCES => return error.AccessDenied,
            .IO => return error.InputOutput,
```

## Links

...
