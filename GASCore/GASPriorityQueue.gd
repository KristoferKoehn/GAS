class_name GASPriorityQueue
extends RefCounted

var _items: Array[GASQueuedExpression] = []

func enqueue(item: GASQueuedExpression) -> void:
	var index: int = _items.size()
	for i: int in range(_items.size()):
		if item.priority < _items[i].priority:
			index = i
			break
	_items.insert(index, item)

func dequeue_next() -> GASQueuedExpression:
	if _items.is_empty():
		return null
	return _items.pop_front()

func peek_next() -> GASQueuedExpression:
	if _items.is_empty():
		return null
	return _items[0]

func is_empty() -> bool:
	return _items.is_empty()

func size() -> int:
	return _items.size()

func clear() -> void:
	_items.clear()
