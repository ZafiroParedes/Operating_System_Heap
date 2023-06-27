_In Progress.._
# Operating System Heap
This exercise is used to implement the concept of how heaps function as memory. The heap is created to organize used and free data in chuncks, making sure nearby free chuncks are merged together to reduce the risk of fragmentation. 

## Chunk Format
_I spelled chunck three different times so idk..._

In order to identify what sections of the heap are used and which are free, chuncks were created that include information about the chunck. Below is the format used for each chunck that was free or contained any data.

![chunck organization image](https://github.com/ZafiroParedes/Operating_System_Heap/assets/91034132/a2fbac4d-e4d9-4b6a-8645-f0eabedb5b6c)


As seen above, every chunck has a code that identifies whether it has data or if it is a free chunck. In this excercise, my code for a chunck with data is labeled as '98989898' and a chunck that is free to use is '12121212'. Then the size is placed right after the code and at the end to symbolize how big the chunck is, either with used data or free data. The size includes all the extra lines around the free or used data of the chunck, such as the identification code and the size.

Chuncks that have data only have the data within the size lines while chuncks that are free to be used by the opertating system instead have the next free chunck memory address after the size and the previous free chunck memory address after that. This helps create a sort of double linked list to look for chuncks that have enough free space for the data entered. Free chuncks can vary therefore there can be empty addresses between the previously free address line and the last size line. 

## Linked List Run

To apply and test the heap was working as intended, a linked list saving a sequence of strings given by a user is used. The picture below shoes the linked list of strings along with the address with the link to the chunck that is storing the next string and the address of where the data begins. 

![linked list program](https://github.com/ZafiroParedes/Operating_System_Heap/assets/91034132/5df7a7a7-fcb7-45c5-b3c6-e0d887d89a8f)


### Recycling and No Fragmentation
It can be noted that when something is deleted from the linked list, the previous chunck is reused since the newer string is the same size as the deleted string. The way the chunck are created, if the next string was larger then the previously deleted chunck would not be used unless there was a larger free chunk nearby.

The first 21 addresses of the heap are shown in the image below. Each line contains the memory address in hexadecimal, the position in the heap, and lastly the contents in the address. This visual representation of the heap created by the program shows the output of the linked list run. Since memory is not cleared right after a chunck has been freed, there ay be 'trash' data that is leftover when a chunck is deleted or reused. For example, on heap[3], there is the line 'FFFFFFFF' left over from when that chunck was free and that code was used to replace the pointer that signifies the end of the list (it is located on the next avilable chunck address).

![image](https://github.com/ZafiroParedes/Operating_System_Heap/assets/91034132/50a22a63-4612-467e-a74f-474b25ebb8ee)

The first four chuncks are in use since there are two strings in the linked list at the end of the program: 'ccc' and 'bbb'. The first chunck only uses five lines and stores the hexacimal version of 'ccc'. The following chunck is the link that saves the address of the data, heap[2], and the next link, heap[11]. The next two chuncks are similar in saving 'bbb' and the address of the data. The last chunck is free with the two addresses to the previous and net being 'FFFFFFFF' because it is the only free chunck in the list. There is also remants from a previous chunck within, starting heap[19], that has been merged with a top chunck to form a larger chunck and reduce fragmentation. 

