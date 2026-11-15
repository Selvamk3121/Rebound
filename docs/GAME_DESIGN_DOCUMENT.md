# REBOUND: The Last Experiment — Game Design Document

## 1. Game Overview
- **Title**: REBOUND — The Last Experiment
- **Genre**: 2D Top-Down Survival Horror / Action Adventure
- **Engine**: Godot 4.7.2 Stable
- **Target Platform**: Desktop PC (Keyboard & Mouse)
- **Viewport**: 640 × 360 (Pixel-art integer scaled, 1280 × 720 window default)

## 2. Core Pillars & Narrative
1. **The Containment Breach**: An investigator infiltrates an underground biotechnology laboratory suspected of illegal bio-weapons development. A catastrophe breaks containment, leaving experimental mutants roaming the corridors.
2. **The Ricochet Weapon**: Standard ballistics fail against mutated biological carapaces. The facility's experimental Security Ricochet Gun fires specialized kinetic rounds that bounce off solid surfaces, turning room geometry into a tactical tool.
3. **Holographic Trajectory Prediction**: Real-time aiming sight reveals the calculated bounce trajectories before firing, aligning preview and physical projectile physics.
4. **Physical World Puzzles**: Electrical circuits, modular fuses, generators, and security bulkheads that maintain real state.

## 3. Sectors & Progression
1. **Sector 1**: Security Sector (Tutorial, weapon discovery, basic movement)
2. **Sector 2**: Research Wing (Laboratories, initial combat encounters)
   - *Safe Zone: Armoury 1 (Fabricator)*
3. **Sector 3**: Power Generation (Generator reboot, fuse puzzle sequences)
4. **Sector 4**: Containment Sector (Heavy biological mutants, Brute encounters)
   - *Safe Zone: Armoury 2 (Fabricator)*
5. **Sector 5**: Advanced Research Wing (Story revelation, Advanced Weapon)
6. **Sector 6**: Central Control (Final confrontation, Escape / Containment / Truth endings)
