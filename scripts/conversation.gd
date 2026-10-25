class_name Conversation


static func play(timeline: String, fox: Player, partner: BaseCharacter = null) -> void:
	if fox.is_talking or Dialogic.current_timeline != null:
		return
	fox.start_talk(partner)
	if partner != null:
		partner.start_talk(fox)
	Dialogic.Choices.use_input_action = true
	Dialogic.start(timeline)
	await Dialogic.timeline_ended
	if is_instance_valid(fox):
		fox.finish_talk()
	if partner != null and is_instance_valid(partner):
		partner.finish_talk()
