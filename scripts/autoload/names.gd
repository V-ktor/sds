extends Node

const VOVELS = ["a","e","o","u","i"]
const CONS = ["b","c","d","f","g","h","j","k","l","m","n","p","r","s","t","v","w","x","y","z"]
const PHRASE = ["alph","bet","gam","a","elt","cent","zen","cap","ri","cor","arc","raz","sher","mir","mark","neb","alt","den","dub","dur","git","quar","sec","shert","term","tri","zet","dia"]
const PHRASE_MIDDLE = ["b","c","d","n","r","t"]
const PHRASE_END = ["us","or","a","ia","er","ion"]


func random_name():
	var name = PHRASE[randi()%(PHRASE.size())]
	var new = PHRASE[randi()%(PHRASE.size())]
	var last = ""
	for i in range(randi()%2):
		var vovel = name[name.length()-1] in VOVELS
		while new==last || (new[0] in VOVELS)==vovel:
			# Make sure the new syllable does not start with a vovel if the last one end with a vovel.
			new = PHRASE[randi()%(PHRASE.size())]
		last = new
		# Append new syllable to name string.
		name += new
		if name.length()>4+randi()%5:
			# Name is long enough.
			break
	# Insert a consonant.
	if name[name.length()-1] in VOVELS:
		name += PHRASE_MIDDLE[randi()%(PHRASE_MIDDLE.size())]
	# Append ending phrase.
	name += PHRASE_END[randi()%(PHRASE_END.size())]
	
	return name.capitalize()

func get_name():
	return random_name()
