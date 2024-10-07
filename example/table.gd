extends Node3D

var card_database = FaceCards.new()
var suits = [
	FaceCards.Suit.CLUB,
	FaceCards.Suit.SPADE,
	FaceCards.Suit.DIAMOND,
	FaceCards.Suit.HEART,
]
var ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

var suit_index = 0
var rank_index = 0


@onready var hand: CardCollection3D = $DragController/Hand
@onready var field_battle: CardCollection3D = $DragController/field_battle
@onready var field_tamer: CardCollection3D = $DragController/field_tamers
@onready var fields: Array[CardCollection3D] = [field_tamer, field_battle]

func _input(event):
	if event.is_action_pressed("ui_down"):
		add_card()
	elif event.is_action_pressed("ui_up"):
		# don't wanna cross wires
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			remove_card()
	elif event.is_action_pressed("ui_left"):
		clear_cards()
	elif event.is_action_pressed("ui_right"):
		if field_battle.card_layout_strategy is PileCardLayout and hand.card_layout_strategy is LineCardLayout:
			var layout := LineCardLayout.new()
			field_battle.card_layout_strategy = layout
		elif hand.card_layout_strategy is LineCardLayout:
			hand.card_layout_strategy = FanCardLayout.new()
		elif field_battle.card_layout_strategy is LineCardLayout:
			field_battle.card_layout_strategy = PileCardLayout.new()
		elif hand.card_layout_strategy is FanCardLayout:
			hand.card_layout_strategy = LineCardLayout.new()


func instantiate_face_card(rank, suit) -> FaceCard3D:
	var scene = load("res://example/face_card_3d.tscn")
	var face_card_3d: FaceCard3D = scene.instantiate()
	var card_data: Dictionary = card_database.get_card_data(rank, suit)
	face_card_3d.rank = card_data["rank"]
	face_card_3d.suit = card_data["suit"]
	face_card_3d.front_material_path = card_data["front_material_path"]
	face_card_3d.back_material_path = card_data["back_material_path"]
	
	return face_card_3d


func add_card():
	var data = next_card()
	var card = instantiate_face_card(data["rank"], data["suit"])
	hand.append_card(card)
	card.global_position = $"../Deck".global_position


func next_card():
	var suit = suits[suit_index]
	var rank = ranks[rank_index]
	
	rank_index += 1
	
	if rank_index == ranks.size():
		rank_index = 0
		suit_index += 1
	
	if suit_index == suits.size():
		suit_index = 0
	
	return {"suit": suit, "rank": rank}


func remove_card():
	if hand.cards.size() == 0:
		return
	
	var random_card_index = randi() % hand.cards.size()
	var card_to_remove = hand.cards[random_card_index]
	
	play_card(card_to_remove)


func play_card(card):
	var card_index = hand.card_indicies[card]
	var card_global_position = hand.cards[card_index].global_position
	var c = hand.remove_card(card_index)
	# plan:
	# make fields, a home for the fields we check on cursor drop
	# cards in the play area need to also add their coords to the indicies because 
	# we can play on top of them.
	# would it work if we checked what pile was closest to the cursor when invoking play_card?
	# maybe set a flag on mouse_enter_drop_zone that we check the list for
	var field = find_hovered_field()
	field.append_card(c)
	c.remove_hovered()
	c.global_position = card_global_position

func find_hovered_field():
	var found = fields.filter(func(field): return field.is_being_hovered)
	return found if found else hand

func clear_cards():
	var hand_cards = hand.remove_all()
	var pile_cards = field_battle.remove_all()
	
	for c in hand_cards:
		c.queue_free()
	
	for c in pile_cards:
		c.queue_free()


func _on_face_card_3d_card_3d_mouse_up():
	add_card()
