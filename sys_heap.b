import "io"

manifest {
	cFreePFree = 3;
	cFreeNFree = 2;
	freeCode = 0x12121212; 
	manFreeSize = 5; //Mandatory size for a free chunk, includes zero

	cUseData = 2;
	useCode = 0x98989898;
	manUseSize = 3; //Mandatory size for a in use chunk, includes zero

	chunkSize = 1;
	chunkCode = 0
}

static {
	heap, firstFree = nil, endFF = -1
}

let printHeap(size) be {
	for i = 0 to (size - 1) do {
		out("%x| heap[%x]: %x \n", @(heap ! i), i, heap ! i);
	}
	out("\n");
}

let setHeap(h, size) be {
	heap := h;

	//from the bottom of the heap
	heap ! chunkCode := freeCode;
	heap ! chunkSize := size; 

	heap ! cFreeNFree := endFF; //no next
	firstFree := 0;//points to whole heap
	heap ! cFreePFree := endFF; //technically no previous

	heap ! (size - chunkSize) := size; 
}

let findFree(size, currChunk) be {
	let nextChunk, currChunkSize = heap ! (chunkSize + currChunk);

	//in the rare case it bumps into an in use
	if (heap ! currChunk) = useCode then {
		nextChunk := currChunk + currChunkSize;
		findFree(size, nextChunk)
	}

	//finds a chunk that is free
	if (heap ! currChunk) = freeCode then {
		if currChunkSize = size then {
			//size of current free chunk is what is needed
			resultis currChunk;
		}
		if (currChunkSize - size) >= manFreeSize then {
			//enough space to have a free chunk if portion is removed for use
			resultis currChunk;
		}
		if (currChunkSize - size) < manFreeSize then {
			//not enough space when in use portion is removed therfore move on to next chunk
			nextChunk := heap ! (currChunk + cFreeNFree);
			findFree(size, nextChunk);
		}
	}
}

let removeFromFL(chunk) be {
	let nextChunk, prevChunk;
	if (heap ! chunk) = useCode then {
		out("Asked to remove a used chunk from free list\n");
		return; 
	}

	nextChunk := heap ! (chunk + cFreeNFree);
	prevChunk := heap ! (chunk + cFreePFree);
	if nextChunk = endFF then {
		heap ! (prevChunk + cFreeNFree) := endFF;
	}
	if not(nextChunk = endFF) then {
		heap ! (nextChunk + cFreePFree) := heap ! (chunk + cFreePFree);
	}
	if prevChunk = endFF then {
		heap ! (nextChunk + cFreePFree) := endFF;
		firstFree := nextChunk;
	}
	if not(prevChunk = endFF) then{
		heap ! (prevChunk + cFreeNFree) := heap ! (chunk + cFreeNFree);
	} 

}

let new_vec(size) be {
	let adjustedSize, freeSize, freeChunk, freeLink, useChunk;

	if size = 0 then {
		out("there is vec of size 0, removed from heap");
		return;
	}

	//size is adjusted to find enough space for data required, size, and 
	//the mandatory three lines
	adjustedSize := size + manUseSize;
	if size = 1 then {
		adjustedSize := adjustedSize + 1;
	}
	
	freeChunk := findfree(adjustedSize, firstFree);
	freeSize := heap ! (freeChunk + chunkSize);
	useChunk := freeChunk;

	//check the status of free chunk 
	if freeSize = adjustedSize then {
		//Just enough for needed data therfore need to remove free from list
		removeFromFL(freeChunk);
	}
	if freeSize > adjustedSize then {
		//since have enough size for free on top, simply push up the next and prev free
		heap ! (freeChunk + adjustedSize + cFreeNFree) := heap ! (freeChunk + cFreeNFree); 
		heap ! (freeChunk + adjustedSize + cFreePFree) := heap ! (freeChunk + cFreePFree);

		//set up leftover free chunk
		freeChunk := freeChunk + adjustedSize;
		freeSize := freeSize - adjustedSize;
		heap ! freeChunk := freeCode;
		heap ! (freeChunk + chunkSize) := freeSize; 
		heap ! (freeChunk + freeSize - chunkSize) := freeSize; 

		if (firstFree = useChunk) then {
			firstFree := freeChunk;
		}
	}
		
	//set up in use chunk
	heap ! useChunk := useCode;
	heap ! (useChunk + chunkSize) := adjustedSize; 
	heap ! (useChunk + adjustedSize - chunkSize) := adjustedSize;

	//give access to the data portion, not the code
	useChunk := useChunk + cUseData; 

	resultis @(heap ! useChunk);
}

//make sure that chunk2 is on top
let mergeAndFree(chunk1, chunk2, sel) be {
	let chunk2Size, chunk1Size, totalSize, transfer;

	chunk2Size := heap ! (chunk2 + chunkSize);
	chunk1Size := heap ! (chunk1 + chunkSize);
	totalSize := chunk2Size + chunk1Size;

	if sel = 0 then { //remove top and merge with bottom
		removeFromFL(chunk2);
		heap ! (chunk1 + chunkSize) := totalSize;
		heap ! (chunk1 + totalSize - chunkSize) := totalSize;
	}
	
	if sel = 1 then { //remove bottom and merge with top
		removeFromFL(chunk1);

		//transfer pointers from top to bottom since bottom removed
		transfer := heap ! (chunk2 + cFreeNFree);
		if not(transfer = endFF) then
			heap ! (transfer + cFreePFree) := chunk1;

		transfer := heap ! (chunk2 + cFreePFree);

		if not(transfer = endFF) then
			heap ! (transfer + cFreeNFree) := chunk1;

		heap ! (chunk1 + cFreeNFree) := heap ! (chunk2 + cFreeNFree);
		heap ! (chunk1 + cFreePFree) := heap ! (chunk2 + cFreePFree);

		heap ! (chunk1 + chunkSize) := totalSize;
		heap ! (chunk2 + chunk2Size - chunkSize) := totalSize;
	}

	return;
}

let free_vec(chunk) be {
	let heapNum, currChunkSize, currChunk; 

	//find the number of the chunk on the heap
	heapNum := @(chunk ! 0) - @(heap ! 0) - cUseData;

	heap ! heapNum := freeCode;

	// add chunk to free chunk list
	heap ! (firstFree + cFreePFree) := heapNum;
	heap ! (heapNum + cFreeNFree) := firstFree;
	heap ! (heapNum + cFreePFree) := endFF;
	firstFree := heapNum;

	//merge possible chunks:

	//first check the chunk on top
	currChunkSize := heap ! (heapNum + chunkSize);
	currChunk := heapNum + currChunkSize;
	if (heap ! currChunk) = freeCode then {
		//merge
		mergeAndFree(heapNum, currChunk, 1);
	}

	//current now checks at the bottom
	currChunkSize := heap ! (heapNum - chunkSize);
	currChunk := heapNum - currChunkSize;
	if (heap ! currChunk) = freeCode then {
		//merge
		mergeandFree(currChunk, heapNum, 0);
	}

	return;
}


/////////////////////////////////////////////////////////////////////
//Start of linked list code

let linkedlist(list, input) be {
	let node = new_vec(2);
	node!0 := input;
	node!1 := list;
	list := node;
	resultis list;
}

let printString(string) be {
	//out("%d ", byte 0 of string);
	for currb = 1 to (byte 0 of string)*4 - 1 do {
		out("%c", byte currb of string);
	}
	out("\n");
}

let printlist(list) be {
	let current, next;
	if list = nil then {
		return;
	}
	// let currptr := list;
	current := list!0;
	next := list!1;
	printlist(next);
	printString(current);
}

let printCurrList(list) be {
	let ptr = list;
	while not(ptr = nil) do {
		out("Link Address: %x | Data Address: %x |  ", @(ptr!1), @(ptr!0));
		printString(ptr!0);
		ptr := ptr!1;
	}
}

let compare(string1, string2) be {
	for i = 1 to (byte 0 of string1) * 4 - 1 do{
		if not(byte i of string1 = byte i of string2) then{
			//out("false\n");
			resultis false;
		}
	}
	resultis true;
}

let findRemove(list, string) be{
	let current, next, del, temp;
	current := list;
	temp := current!0;

	if compare(temp, string) then { //start of the list
		del := current;
		list := current!1;
		free_vec(del!0);	
		free_vec(del);
		//out("found del1\n");
		resultis list;
	}

	if not(compare(current!0, string)) then {
		while not(current!1 = nil) do {
			next := current!1;
			if compare(next!0, string) then{
				current!1 := next!1;
				del := next;
				free_vec(del!0);
				free_vec(del);
				//out("found del2\n");
				resultis list;
			}
			current := next;
		}
	}
}

let delete(list, string) be {
	let length = (byte 0 of string) - 2; //assuming the first two are DELETE
	let sepString = new_vec(length);

	byte 0 of sepString := length;
	for i = 1 to (length * 4) - 1 do{
		byte i of sepString := byte (i + 7) of string; // assuming bytes 0 to 7 are 'DELETE '
	}
	list := findRemove(list, sepString);
	free_vec(sepString);
	resultis list;
}

let permInput(input) be {
	let length = byte 0 of input;
	let perman = new_vec(length);
	for i = 0 to length - 1 do
		perman!i := input!i;
	resultis perman;
}

let readInput() be{
	let char, input = vec(100);
	for  i = 0 to 396 do {
		byte i of input := 0;
	}
	for lengthb = 1 to 396 do {
			char := inch();
			if char = '\n' then {
				if (lengthb) rem 4 = 0 then{
					byte 0 of input := ((lengthb) / 4);
				}
				if not((lengthb) rem 4 = 0) then
					byte 0 of input := ((lengthb) / 4) + 1;
				resultis input;
			}
			byte lengthb of input := char;
	}
}

let del() be {
	let del = vec(3);
	byte 0 of del := 2;
	byte 1 of del := 'D'; byte 2 of del := 'E'; byte 3 of del := 'L'; byte 4 of del := 'E'; byte 5 of del := 'T'; byte 6 of del := 'E';
	resultis del;
}

let start() be {
	let array = vec(1000);
	let input, end = false, permIn = nil;
	let list = nil;

	setHeap(array, 1000);
	//init(array, 1000);
	//let DEL = del(); //initalize above init

	out("Write a sequence of strings, each string separated by the ENTER key. To stop sequence type 'END' \nTo delete a word type 'DELETE' \nTo print all current list without stopping type 'ALL'\n");
	while true do {
		while true do {
			input := readInput();
			if byte 1 of input = 'E' /\ byte 2 of input = 'N' /\ byte 3 of input = 'D' then {
				end := true;
				break;
			}
			if byte 1 of input = 'A' /\ byte 2 of input = 'L' /\ byte 3 of input = 'L' then {
				break;
			}
			if (byte 1 of input = 'D' /\ byte 2 of input = 'E' /\ byte 3 of input = 'L' /\ byte 4 of input = 'E' /\ byte 5 of input = 'T' /\ byte 6 of input = 'E') then {
				list := delete(list, input);
			}
			if not(byte 1 of input = 'D' /\ byte 2 of input = 'E' /\ byte 3 of input = 'L' /\ byte 4 of input = 'E' /\ byte 5 of input = 'T' /\ byte 6 of input = 'E') /\ not(byte 1 of input = 'A')then{
				permIn := permInput(input);
				//printString(permIn);
				list := linkedlist(list, permIn);
				}
			}

			if end then break;	
			printCurrList(list);
		}

	out("Here is your sequence of strings:\n");
	printlist(list);
	out("Here is the final set of addresses:\n");
	printCurrList(list);
	
	printHeap(40);
}
