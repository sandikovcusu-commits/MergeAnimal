"""Static invariants only; these checks do not execute Godot or its physics."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return (ROOT / path).read_text(encoding='utf-8')


def animal(name):
    text = read(f'resources/animals/{name}.tres')
    return {key: value.strip() for key, value in re.findall(r'^(\w+) = (.+)$', text, re.M)}


class StaticContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.names = ['mouse', 'hamster', 'rabbit', 'cat', 'dog', 'fox', 'raccoon', 'koala', 'panda', 'bear', 'lion', 'elephant']
        cls.animals = [animal(name) for name in cls.names]
        cls.game = read('scripts/gameplay/Game.gd')
        cls.merge = read('scripts/managers/MergeManager.gd')
        cls.scene = read('scenes/game/Game.tscn')

    def test_unique_ids(self):
        self.assertEqual([a['id'] for a in self.animals], [f'&"{n}"' for n in self.names])

    def test_contiguous_levels(self):
        self.assertEqual([int(a['level']) for a in self.animals], list(range(1, 13)))

    def test_strict_radius_progression(self):
        radii = [float(a['radius']) for a in self.animals]
        self.assertEqual(radii, [18, 23, 29, 35, 42, 50, 59, 69, 80, 93, 108, 125])
        self.assertTrue(all(a < b for a, b in zip(radii, radii[1:])))

    def test_positive_mass(self):
        self.assertTrue(all(float(a['body_mass']) > 0 for a in self.animals))

    def test_physics_material_ranges(self):
        for a in self.animals:
            for key in ('friction', 'bounce'):
                self.assertTrue(0 <= float(a[key]) <= 1)

    def test_scores_match_balance_table(self):
        self.assertEqual([int(a['merge_score']) for a in self.animals], [2, 4, 8, 12, 20, 32, 48, 70, 100, 150, 220, 500])

    def test_same_scene_references_all_resources(self):
        for name in self.names:
            self.assertIn(f'res://resources/animals/{name}.tres', self.scene)

    def test_wall_inner_faces_match_game_bounds(self):
        self.assertIn('size = Vector2(32, 830)', self.scene)
        self.assertIn('position = Vector2(75, 695)', self.scene)
        self.assertIn('position = Vector2(645, 695)', self.scene)
        self.assertEqual((75 + 16, 645 - 16, 1110 - 16), (91, 629, 1094))
        for expected in ('left_bound: float = 91.0', 'right_bound: float = 629.0', 'floor_height: float = 1094.0'):
            self.assertIn(expected, self.game)

    def test_preview_uses_same_script_as_bodies(self):
        visual = 'res://scripts/gameplay/AnimalVisual.gd'
        self.assertIn(visual, self.scene)
        self.assertIn(visual, read('scenes/animals/Animal.tscn'))

    def test_contact_monitor_enabled(self):
        scene = read('scenes/animals/Animal.tscn')
        self.assertIn('contact_monitor = true', scene)
        self.assertIn('max_contacts_reported = 8', scene)
        self.assertIn('body_entered.connect', self.merge)

    def test_project_disables_input_emulation(self):
        project = read('project.godot')
        self.assertIn('pointing/emulate_touch_from_mouse=false', project)
        self.assertIn('pointing/emulate_mouse_from_touch=false', project)

    def test_scene_has_pause_and_restart_buttons(self):
        for button in ('PauseButton', 'ResumeButton', 'RestartButton'):
            self.assertIn(f'name="{button}" type="Button"', self.scene)


if __name__ == '__main__':
    unittest.main(verbosity=2)
