[![Build Status](https://github.com/hmlendea/more-cultural-names-ek/actions/workflows/build.yml/badge.svg)](https://github.com/hmlendea/more-cultural-names-ek/actions/workflows/build.yml)

# About

This is a sub-mod for CK2's Elder Kings mod that add new culture-specific names and localisations.

It currently brings around **2,350** new cultural landed title names!
It was last updated for EK version 0.2.3.5, CK2 version 3.0.1.1

Note: The vast majority of those names are made-up, as in the canon we only have very few places with their names translated into other language.

# Useful links

- [GitHub page](https://github.com/hmlendea/ck2-ek-mcn)
- [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=1745899430)

# Installation

Just subscribe to the [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=1745899430) of this mod.

If you don't own this game on Steam, or you want to try the in-development version, you can download the latest release from the [GitHub page](https://github.com/hmlendea/ck2-ek-mcn/releases) and extract the contents into your "mod" directory alongside your current EK installation.

**Note:** This mod is OS-agnostic, which means it will work on all operating systems supported by CK2 and EK (Windows, Linux and Mac)

**REQUIREMENTS:**
- This mod requires up-to-date EK
- Backwards-compatibility with older EK versions is intended but not guaranteed.

**UPDATING THE MOD:**
- This mod gets updated more frequently on GIT than on the Steam Workshop.
- When manually updating, please remove all the previous files of this mod.

# Contributions

You are welcome to bring any suggestion, feedback or modification to this project.

There are a few ways you can do so:

1. You can create git pull requests for this repository (This requires git knowledge)
2. You can raise a new "[issue](https://github.com/hmlendea/ck2-ek-mcn/issues)" for this project
4. You can reply on the [Steam discussion thread](https://steamcommunity.com/workshop/filedetails/discussion/1745899430/2530372519569641320/)

It would also be very helpful if you could provide a link to a source that can atest the authenticity of the names you submitted, when possible.

The guidelines and roadmap can be found in the github project description.

# Development focus

Currently, the development focuses on the following areas:

- Landed title names any culture, anywhere
- Missing EK names for counties and baronies that both have the same name but only one (usually the county, or even just the barony) has culture-specific names associated with it
- Minor titles and jobs localisations

# Development guidelines

- Encode files with the `WINDOWS-1252` character set
- Make sure the names you add are historically accurate for the medieval era
- Do not override names already provided by EK, unless there is a good reason to do so
- Check with the original EK files and take note of the already existing names (especially for similar cultures) and the name displayed ingame (which might be very different from the internal name in the files, e.g. `d_galich` is Halych ingame)
- Make sure there are no other dependencies than EK itself.
- Only use a suffix for another suffix of the original native language
- Sometimes it makes sense to match certain parts of a name to a word, but make sure you do it in all instances where it appears

Additional guidelines and rules can be found in header comments inside specific files.
