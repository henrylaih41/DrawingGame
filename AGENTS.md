# Contributor Guide

## Coding guidelines
1. Do not hardcode any constant, alway make them configurable
2. When writing Roblox server or client scripts, keep in mind of the possibile initialization delay. Also use WaitForChild if possible, never assume anything to always exists, follow general good Roblox development practice.

## Testing Instructions
For each PR, try to add unit test. 
The server tests are in src/server/tests
The client tests is not created yet. If you created one, update it here.

## Memory
If you make a mistake, add a note to AGENTS.md to avoid from making the same mistake again.
