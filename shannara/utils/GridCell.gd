# GridCell data structure for 3D dungeon grid system
# Handles x, y coordinates, elevation (Z-level), walkability, and terrain type

class_name GridCell
extends Resource

var x: int = 0
var y: int = 0
var elevation: int = 0  # -1 = fossato, 0 = piano, 1 = altezza
var walkable: bool = true
var occupant: Node = null
var terrain_type: int = TerrainType.FLOOR

func grid_cell_factory(p_x: int, p_y: int, p_elevation: int = 0) -> GridCell:
	var cell := GridCell.new()
	cell.x = p_x
	cell.y = p_y
	cell.elevation = clamp(p_elevation, -1, 1)
	return cell