class_name GASStatementCounter
extends RefCounted

func count_source(source: String) -> int:
	var lexer: Lexer = Lexer.new(source)
	var parser: PrattParser = PrattParser.new(lexer.tokens)
	var ast: Expr = parser.parse()
	if ast == null:
		return 0
	if ast is BlockExpr:
		var block: BlockExpr = ast as BlockExpr
		return block.statements.size()
	return 1

func count_file(path: String) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var content: String = file.get_as_text()
	file.close()

	var total: int = 0
	var blocks: Array = GASBlockSplitter.split(content)
	for block: Dictionary in blocks:
		var block_content: String = block.get("content", "") as String
		total += count_source(block_content)
	return total
