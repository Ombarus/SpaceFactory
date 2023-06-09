extends Node

const BuildingList := {
	"miner":preload("res://scenes/Miner.tscn"),
	"smelter":preload("res://scenes/Smelter.tscn"),
	"floor":preload("res://scenes/Floor.tscn"),
	"wall":preload("res://scenes/Wall.tscn"),
	"solar":preload("res://scenes/Solar.tscn")
}

var JsonCache = {}
