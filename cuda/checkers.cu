#include<cstdio>

#define EMPTY 0
#define WHITE 1
#define BLACK 2
#define queenW 11
#define queenB 22

struct checkers_point{
    int board[64];
    int how_much_children;
    checkers_point * children = NULL;
    checkers_point * next = NULL;
    checkers_point * parent = NULL;
    bool min_max;
    int value;
    int player;
};

extern "C" {

__device__
int pawn_owner(int * tab, int x, int y){
    if (tab[x*8+y] == BLACK || tab[x*8+y] == queenB)
        return BLACK;
    if (tab[x*8+y] == WHITE || tab[x*8+y] == queenW)
        return WHITE;
    return EMPTY;
}

__device__
bool is_queen(int * tab, int x, int y){
	int n = 8;
    return (tab[x*n+y] == queenB || tab[x*n+y] == queenW);
}

__device__
bool is_a_pawn(int * tab, int x, int y){
    return !(tab[x*8+y] == EMPTY);
}

__device__
bool correct_kill(int * tab, int x, int y, int x1, int y1){
    if (!is_a_pawn(tab, x1, y1))
	return false;
    if (pawn_owner(tab, x, y) != pawn_owner(tab, x1, y1))
        return true;
    return false;
}


__device__
bool queen_way(int * tab, int x, int y, int x1, int y1){
    int own = pawn_owner(tab, x, y);
    int x_r = x > x1 ? -1 : 1, y_r = y > y1 ? -1 : 1;
    bool next_empty = false;
    x += x_r; y += y_r;
    while (x != x1){
        if (is_a_pawn(tab, x, y)){
            if (next_empty)
                return false;
            next_empty = true;
            if (pawn_owner(tab, x, y) == own)
                return false;
        } else {
            next_empty = false;
        }
        x += x_r; y += y_r;
    }
    return true;
}

__device__
bool is_move_correct(int * tab, int x, int y, int who, int x1, int y1){
    int n = 8;
    if (x < 0 || x >= n || x1 < 0 || x1 >= n || y < 0 || y >= n || y1 < 0 || y1 >= n ){
	printf("WRONG VALUE");
        return false;
    }
    if (std::abs(x-x1) != std::abs(y-y1)){
	printf("ABS PROBLEM");
        return false;
    }
    int pwn_wnr = pawn_owner(tab, x, y);
    if (pwn_wnr == EMPTY){
	printf("PAWNOWNEREMPTY");
        return false;
    }
    if (pwn_wnr != who){
	printf("LOL");
        return false;
    }
    if (is_a_pawn(tab, x1, y1)){
	printf("pawn in _");
        return false;
    }
    if (x < x1 && who == WHITE && tab[x*n+y] != queenW){
	printf("WHITE WRONG WAY");
        return false;
    }
    if (x > x1 && who == BLACK && tab[x*n+y] != queenB){
	printf("BLACK WRONG WAY");
        return false;
    }
    if ((tab[x*n+y] == queenW || tab[x*n+y] == queenB) && (!queen_way(tab, x, y, x1, y1))){
        printf("queen problem");
	return false;
    }
    if (!is_queen(tab, x, y) && std::abs((x-x1)) > 1 && !correct_kill(tab, x, y, (x1+x)/2, (y1+y)/2)){
        printf("Correct kill problem");
	return false;
    }
    return true;
}

__device__
	void copy_board(checkers_point * ch, checkers_point * ch2){
		for (int i = 0; i < 64; i++){
			ch2->board[i] = ch->board[i];
		}
	}

__device__
	checkers_point * pawn(checkers_point * ch, int x, int y, int x1, int y1, bool &nxt, bool br){
		if (is_move_correct(ch->board, x, y, pawn_owner(ch->board, x, y), x1, y1) == true){
			printf("CORR!");
			checkers_point * chld;
                        if (!nxt){
				printf("NEXT");
                                ch->children = new checkers_point;
				ch->children->parent = ch;
				chld = ch->children;
                        } else {
				ch->next = new checkers_point;
				ch->next->parent = ch->parent;
                        	chld = ch->next;
			}
                        copy_board(chld->parent, chld);
			/*
			chld->value = 123;
                        chld->board[x1*8+y1] = chld->board[x*8+y];
                        chld->board[x*8+y] = EMPTY;
                        chld->board[(x+x1)/2*8+(y+y1)/2] = EMPTY;
			/*
			ch = chld;
			nxt = true;
			printf("%d, %d -> %d, %d\n", x, y, x1, y1);
			/*
			if (ch->board[x1*8+y1] == WHITE){
	                	ch = pawn(ch, x1, y1, x1-2, y1-2, nxt);
        	        	ch = pawn(ch, x1, y1, x1-2, y1+2, nxt);
			} else {
		                ch = pawn(ch, x1, y1, x1+2, y1-2, nxt);
  		                ch = pawn(ch, x1, y1, x1+2, y1+2, nxt);
			}
			*/
		}
		return ch;
	}

__device__
    checkers_point * dismember_child(checkers_point * ch, int x, int y, bool nxt, int turn_no){
	checkers_point * chb = ch->parent;
	if (chb == NULL){
		printf(" NO PARENT ");
		chb = ch;
	}
	printf("NR %d\n", chb->value); 
	switch(chb->board[x*8+y]){
	    case WHITE:
		if (turn_no % 2 == 0){
		printf("WHITE ");
		ch = pawn(ch, x, y, x-1, y-1, nxt, false);
                ch = pawn(ch, x, y, x-1, y+1, nxt, false);
		ch = pawn(ch, x, y, x-2, y-2, nxt, false);
		ch = pawn(ch, x, y, x-2, y+2, nxt, false);
		}
		break;
	    case BLACK:
		if (turn_no % 2 == 1){
		printf("BLACK %d %d", x, y);
		ch = pawn(ch, x, y, x+1, y-1, nxt, false);
  //              ch = pawn(ch, x, y, x+1, y+1, nxt, false);
//		ch = pawn(ch, x, y, x+2, y-2, nxt, false);
  //              ch = pawn(ch, x, y, x+2, y+2, nxt, false);
		}
		break;
	    default:
		break;
	}
	return ch;
    }

__device__
//add global size
    void ramification(checkers_point * ch2, int thid, int how_deep){
	bool nxt = false;
	printf("!%d!\n", how_deep);
	for (int i = 0; i < 8*8; i++){
	    if (ch2->board[i] != EMPTY){
		ch2 = dismember_child(ch2, i/8, i % 8, nxt, how_deep);
		nxt |= true;
	    }
	} 
	/*
        int pseudo_rand = thid % 7 + 2;
	
        if (!(thid == 0 && how_deep == 1))
            printf("%d | %d | %d | %d\n", thid, ch2->value, pseudo_rand, ch2->parent->value);
        else {
            printf("%d | %d\n", thid, pseudo_rand);
        }
	
        ch2->how_much_children = pseudo_rand;
        ch2->children = new checkers_point;
        ch2->children->value = ch2->value*100+1;
        ch2->children->parent = ch2;
        ch2 = ch2->children;
        for (int j = 1; j < pseudo_rand; j++){
            ch2->next = new checkers_point;
            ch2->next->value = ch2->value+1;
            ch2->next->parent = ch2->parent;
            ch2 = ch2->next;
        }
	*/
    }
    
__global__
    void create_tree(int n, checkers_point * ch, int how_deep){
        int thid = (blockIdx.x * blockDim.x) + threadIdx.x;
        int find_me = thid;
        int count_group = n;
            __syncthreads();
        if (thid < n){
            checkers_point * ch2 = ch;
            for (int i = 0; i < how_deep; i++){
                if (find_me == 0 && i + 1 == how_deep){
                    ramification(ch2, thid, how_deep);
                }
                __syncthreads();
                if (i + 1 == how_deep)
                    break;
                count_group = count_group/ch2->how_much_children;
                int group = find_me/count_group;
                if (group >= ch2->how_much_children)
                    break;
                find_me = find_me % count_group;
                ch2 = ch2->children;
                for (int k = 0; k < group; k++)
                    ch2 = ch2->next;
                __syncthreads();
            }
        }
    }
    
    
__device__
    void print_tr(checkers_point * ch){
        if (ch == NULL)
            return;
        print_tr(ch->children);
        print_tr(ch->next);
        printf("%d\n", ch->value);
    }
        
__global__
    void print_tree(int n, checkers_point * ch, int i){
        int thid = (blockIdx.x * blockDim.x) + threadIdx.x;
        if (thid == 0){
            printf("____\n");
            print_tr(ch);
            printf("____\n");
        }
    }

__global__
    void set_root(checkers_point * ch, int * tab, int size){
        int thid = (blockIdx.x * blockDim.x) + threadIdx.x;
        if (thid == 0){
	    ch->value = 1;
//	    ch->children = NULL;
//	    ch->next = NULL;
	    for (int i = 0; i < size*size; ++i)
		ch->board[i] = tab[i]; 
        }
    }

__global__
    void copy_best_result(checkers_point * ch, int * tab, int size){
        int thid = (blockIdx.x * blockDim.x) + threadIdx.x;
        if (thid == 0){
	//find the best board!
            for (int i = 0; i < 64; ++i)
                tab[i] = ch->board[i];
        }
    }

}
