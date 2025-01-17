# CritForcist

## Overview

Welcome to **CritForcist**, my fun little project for World of Warcraft players who love to see their critical hits celebrated with flair! This addon will keep track of your highest crits, announce new records in party chat, and show a stylish popup animation on screen.

## Features

- **Track Highest Crits**: Records your highest critical hits for each spell or auto-attack.
- **Announcements**: Shares your new high crit records in party chat (with a cooldown to avoid spam).
- **Visual Feedback**: Displays a flashy animation with the spell icon, name, and crit amount when you break your record.
- **Sound Alert**: Plays a sound to grab your attention when you achieve a new record crit.

## How It Works

- The addon listens to combat log events for `SPELL_DAMAGE` and `SWING_DAMAGE`.
- When a critical hit is detected and is higher than the previously recorded highest crit for that spell, it:
  - Updates the internal database.
  - Announces the new record to the party chat (if you're in a group).
  - Shows an animation on your screen.

## Installation

1. Download the addon from this repository.
2. Place the `CritForcist` folder into your `World of Warcraft/_retail_/Interface/AddOns` directory.
3. Restart or reload your WoW client to enable the addon.

## Commands

- `/cft` - Triggers a test animation for debugging or showing off.

## Limitations

- This is a personal project for fun, so it lacks:
  - An options menu for customization.
  - Additional animations or sound options.
  - Multi-character tracking across different sessions.

## Future Enhancements

- **Options Menu**: Allow customization of animations, sound, and chat announcements.
- **More Animations**: Add different animation styles or let users choose from a set.
- **Sound Customization**: Add different sound effects with toggle options.
- **Persistence**: Implement better saving mechanisms for multi-session tracking across characters.

## Contributions

Feel free to fork this project, contribute, or suggest improvements. Remember, this is intended to be a light-hearted, fun addon!

## License

This project is released under the [MIT License](LICENSE).

## Contact

For questions or collaboration, feel free to reach out through GitHub issues or pull requests.

Enjoy your crits with style!
