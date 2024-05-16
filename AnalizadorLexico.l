%{
/*
Universidad Nacional Autónoma de México
        Facultad de ingeniería
Compiladores                   Grupo 03
Profesora:  M.C. LAURA SANDOVAL MONTAÑO
Integrantes: 
                 Alcantar Correa Vianey
         Sánchez Rosas Alexis Alejandro

Objetivo:Elaborar un analizador léxico 
en lex/flex que reconozca los 
componentes léxicos pertenecientes a 
las 10 clases descritas en clase.
*/
/*Importar bibliotecas necesarias*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h> //Utiliza -lm al momento de compilar

/*
Estructura para guardar los datos de los identificadores 
posicion, nombre y tipo respectivamente
*/

typedef struct{
	int pos;
	char* name;
	int type ;
}identificador;
/*Apuntador para archivo de salida*/
FILE* outFile,*tokenFile,*tableFile;


/*Arreglos dinamicos de tamanio inicial 100 para almacenar las tablas de simbolos,literales y de reales*/
identificador *symbolTable;
float 	*realTable;
char 	**stringTable;
char	**charTable;
//Tabla de operadores relacionales, de asignacion y de palabras reservadas son estaticas lo que nos ahorra trabajo
char 	*resWordTable[] = {"ent","finsi","haz","mientras","large","para","real","regresa","si","simb","sino"};
char 	*relOpTable[] = {"=","/=",">=",">","<","<="};
char 	*asigOpTable [] = {"->"};
/********************************
Variables auxiliares
ponterTS = Tabla de simbolos; pointerTL = Tabla de literales; pointer TR = Tabla de reales
sizeTS = tamanio TS sizeTL = tamanio TL sizeTR = tamanio TR
**********************************/
int 	pointerTS = 0, pointerTLString = 0, pointerTLChar = 0, pointerTR = 0;
int 	sizeTS = 100, sizeTLString = 10, sizeTLChar = 10, sizeTR = 100;
/*****************************Prototipos de función*******************************/
//Función para crear tabla de tokens
void writeToken(int class, int value);
//Funciones para tabla de simbolos
int	addToSymbTab (char* yytext());
void 	printSymbolTable();
//Función para convertir caracter a su correspondiente ASCII
int toASCII(char* yytext());
//Función para consultar tabla de operadores relacionales
int relIndex(char* yytext());
//Función para consultar tabla de palabras reservadas
int resWordIndex(char* yytext());
//Funcion para consultar tabla de operadores de asignacion
int asigIndex(char* yytext());
//Funciones para agregar constantes cadenas y caracteres a sus respectivas tablas
void addToStringTable(char* yytext);
void addToCharTable(char* yytext);
//Funcion para agragar reales a su respectiva tabla
void addToRealTable(float yytext);
//Funcion para convertir octal a decimal y hexa a decimal
int convertOctalToDecimal(char * yytext);
int convertHexaToDecimal(char * yytext);
//Funciones para imprimir tablas
void printStringTable();
void printCharTable();
void printRealTable();
%}

space 				[ ]
saltolinea 			[\n]+
minus 				[a-z]
mayus 				[A-Z]
dig 				[1-9]
digcero 			[0-9]

identificador 			{minus}({minus}|_)*
identWRONG			({minus}|{mayus}|_|-)*
charWRONG			\'[^\']{2,}\'
simbesp 			[\(\)\{\};,\[\]]
oprelacional 			"="|"/="|">="|">"|"<"|"<="
opasignacion 			"->"
palres 				ent|finsi|haz|mientras|large|para|real|regresa|si|simb|sino
oparitmeticos 			\+|\-|\*|\/|\%
constentera			{dig}({digcero})*
constoctal			0[0-7]+
consthexa			0[xX][0-9a-fA-F]+
constcadena			\"[^\"]*\"
constcaracter 			\'[^\']{1}\'
constreal			{digcero}*\.{digcero}+

%%
{space}				{}
{saltolinea}			{}
{palres}			{ writeToken(4, resWordIndex(yytext)); }
{identificador} 		{ writeToken(0, addToSymbTab(yytext)); }
{simbesp}			{ writeToken(1, toASCII(yytext)); }
{oprelacional}  		{ writeToken(2, relIndex(yytext)); }
{opasignacion}			{ writeToken(3, asigIndex(yytext)); }
{oparitmeticos}			{ writeToken(5, toASCII(yytext)); }
{constoctal}			{ writeToken(6, convertOctalToDecimal(yytext)); }
{consthexa}			{ writeToken(6, convertHexaToDecimal(yytext)); }
{constentera}			{ writeToken(6, atoi(yytext)); }
{constcadena}			{ addToStringTable(yytext); writeToken(7, pointerTLString-1); }
{constcaracter} 		{ addToCharTable(yytext); writeToken(8, pointerTLChar-1); }
{constreal} 			{ addToRealTable(atof(yytext)); writeToken(9,pointerTR-1); }
{identWRONG}			{ fprintf (outFile,"%s ERROR LEXICO \n",yytext); }
{charWRONG}			{ fprintf (outFile,"%s ERROR LEXICO \n",yytext); }
.				{ fprintf (outFile,"%s ERROR LEXICO \n",yytext); }
 
%%

void writeToken(int class, int value) {
    switch(class){
        case 0:		//Identificadores
            fprintf(outFile,"identificador: %s con Token: ( %d,%d )\n",yytext,class,value );
            break;
        case 1:		//Simbolo especial
            fprintf(outFile,"Simbolo especial: '%s' con Token: ( %d,%d )\n",yytext,class,value );
            break;
        case 2:		//Operador relacional
            fprintf(outFile,"Operador relacional: %s con Token: ( %d,%d )\n",yytext,class,value );
            break;
        case 3:		//Operador de asignacion (caso especial, 2 caracteres y solo un elemento en la tabla)
            fprintf(outFile,"Operador de asignacion: %s con Token: ( %d,%d )\n",yytext,class,value );
            break;
        case 4:		//Palabras reservadas
            fprintf(outFile,"Palabra reservada: %s con Token: ( %d,%d )\n",yytext,class,value );
            break;  
        case 5:		//Operadores aritmeticos
            fprintf(outFile,"Operador aritmetico: %s con Token: ( %d,%d )\n",yytext,class,value );
    		break;
		case 6:		//Constantes numericas enteras
            fprintf(outFile,"Constante numerica entera: %s con Token: ( %d,%d )\n",yytext,class,value );
			break;
        case 7:		//Constantes cadenas
            fprintf(outFile,"Constante cadena: %s con Token: ( %d,%d )\n",yytext,class,value );
            break;
        case 8:		//Constantes caracter
            fprintf(outFile,"Constante caracter: %s con Token: ( %d,%d )\n",yytext,class,value );
    		break;
	    case 9:		//Constante real
            fprintf(outFile,"Constante numerica real: %s con Token: ( %d,%d )\n",yytext,class,value );
			break;
        default:
       		 break;
    }
        fprintf(tokenFile,"%d,%d\n",class,value);
}

int addToSymbTab (char* yytext()){
   	 // Asigna el inicio de un bloque de memoria dinámica al apuntador ptr
	char *ptr = calloc(strlen(yytext) + 1, sizeof(char));
	if (ptr == NULL) {
	printf("Error: memoria insuficiente.\n");
	exit(1);
	}
	// Copia el contenido de yytext a ptr
	strcpy(ptr, yytext);
	
   	 for (int i = 0; i < pointerTS; i++) {
	// Guarda en el apuntador name el nombre del identificador que se encuentra en la posición i del arreglo
		char *name = symbolTable[i].name;
	// Compara name con el apuntador ptr en caso de haber coincidencia
		if (strcmp(name, ptr) == 0) {
    // Retorna el valor del índice que corresponde a la posición en la tabla de símbolos para este identificador
		    symbolTable[i].pos = i;
		    return i;
		}						
    }  
        
    if (pointerTS == sizeTS) {
        sizeTS *= 2;
        stringTable = realloc(stringTable, sizeof(char*) * sizeTS);
        if (stringTable == NULL) {
            printf("Error: memoria insuficiente.\n");
            exit(1);
        }
    }
    
    symbolTable[pointerTS].name = ptr;
    symbolTable[pointerTS].type = -1;
    pointerTS++;
    
    // Retorna el valor del índice que corresponde a la posición en la tabla de símbolos para este identificador
    return pointerTS - 1;
}



//Función para convertir caracter a su respectivo ASCII

int toASCII(char* yytext()){
	char *aux = calloc(strlen(yytext) + 1, sizeof(char));
	int ret;
	if (aux == NULL) {
		printf("Error: memoria insuficiente.\n");
		exit(1);
	}
	// Copia el contenido de yytext a aux
	strcpy(aux, yytext);
	
	fprintf (outFile,"Convirtiendo caracter %s a su ASCII ---> %d\n",aux,(int)aux[0]);
	ret = (int)aux[0];
	free(aux);
	return ret;
}

//Función para obtener el valor del operador en su tabla
int relIndex(char* yytext()) {
    	// 6 = tamaño de tabla de operadores relacionales
    for (int i = 0; i <= 6; i++) {
        // Compara la cadena que entra a la función con cada cadena del arreglo de operadores relacionales
        if (strcmp(yytext, relOpTable[i]) == 0) {
            return i;
        }
    }
    return -1;
}

//Función para obtener el valor de la palabra reservada en su tabla
int resWordIndex(char* yytext()){
    	// 10 = tamaño de tabla de palabras reservadas
    for (int i = 0; i <= 10; i++) {
        // Compara la cadena que entra a la función con cada cadena del arreglo de palabras reservadas
        if (strcmp(yytext, resWordTable[i]) == 0) {
            return i;
        }
    }
    return -1;
}

//Función para obtener el valor de operador de asignacion en su tabla
int asigIndex(char* yytext()){
	for (int i = 0; i <= 10; i++) {
        // Compara la cadena que entra a la función con cada cadena del arreglo de operadores de asignacion
        if (strcmp(yytext, asigOpTable[i]) == 0) {
            return i;
        }
    }
    return -1;
}
// Función para agregar una cadena a la tabla de cadenas
void addToStringTable(char* yytext){
    // Asigna memoria dinámicamente para la cadena
    char *ptr = (char*)malloc(sizeof(char) * (strlen(yytext) + 1));
    // Copia el contenido de la cadena 'yytext' en la cadena recién asignada
    strcpy(ptr, yytext);
    // Verifica si el índice actual es igual al tamaño de la tabla de cadenas
    if(pointerTLString == sizeTLString){
        // Si es así, duplica el tamaño de la tabla
        sizeTLString *= 2;
        // Usa 'realloc()' para asignar la nueva cantidad de memoria y mantener los valores previos de la tabla
        stringTable = realloc(stringTable, sizeof(char*) * sizeTLString);
    }
    // Almacena el puntero de la cadena recién asignada en la tabla de cadenas
    stringTable[pointerTLString] = ptr;
    // Incrementa el índice para la próxima cadena
    pointerTLString++;
}

// Función para agregar un caracter a la tabla de cadenas
void addToCharTable(char* yytext){
    // Asigna memoria dinámicamente para la cadena
    char *ptr = (char*)malloc(sizeof(char) * (strlen(yytext) + 1));
    // Copia el contenido de la cadena 'yytext' en la cadena recién asignada
    strcpy(ptr, yytext);
    // Verifica si el índice actual es igual al tamaño de la tabla de cadenas
    if(pointerTLChar == sizeTLChar){
        // Si es así, duplica el tamaño de la tabla
        sizeTLChar *= 2;
        // Usa 'realloc()' para asignar la nueva cantidad de memoria y mantener los valores previos de la tabla
        charTable = realloc(charTable, sizeof(char*) * sizeTLChar);
    }
    int ret = (int)ptr[1];
    printf("%s es igual a %d\n",yytext,ret);
    // Almacena el puntero de la cadena recién asignada en la tabla de cadenas
    charTable[pointerTLChar] = ret;
    // Incrementa el índice para la próxima cadena
    pointerTLChar++;
}
void addToRealTable(float yytext){
   if(pointerTR == sizeTR){
        sizeTR *= 2;
        stringTable = realloc(stringTable, sizeof(char*) * sizeTR);
    }
    realTable[pointerTR] = yytext;
    pointerTR++;
}

/* Función para convertir un número octal a decimal */
// Convierte un número octal representado como una cadena de caracteres en su equivalente decimal y lo devuelve como un entero
int convertOctalToDecimal(char * yytext) {
    
    // Crea una nueva cadena de caracteres para almacenar el número octal sin el primer carácter "0"
    char *ptr = malloc(sizeof(char) * (strlen(yytext) - 1));
    for(int i = 0; i < strlen(yytext)-1; i++){
        ptr[i] = yytext[i+1];
    }
    // Convierte la cadena de caracteres en un entero
    int n = atoi(ptr); 
    // Inicializa las variables que se usarán en el proceso de conversión a decimal
    int p = 0, decimal = 0, r;  
    // Convierte el número octal en decimal utilizando el método de división sucesiva por 10
    while(n>0){       
        // Calcula el residuo de la división de n entre 10
        r = n % 10;
        // Divide n entre 10
        n = n / 10; 
        // Agrega el residuo al número decimal multiplicado por 8 elevado a la potencia p
        decimal = decimal + r * pow(8, p);         
        // Incrementa la potencia de 8
        ++p;
    }
    // Devuelve el número decimal resultante
    fprintf(outFile,"Convirtiendo %s en base octal a base decimal -> %d\n",yytext,decimal);
    return decimal;
}

int convertHexaToDecimal(char* yytext){
	// reserva memoria para la cadena c
    char *ptr = malloc(sizeof(char) * (strlen(yytext) - 2)); 
    // recorre la cadena yytext para obtener los dígitos hexadecimales a convertir
    for(int i = 0; i < strlen(yytext)-2; i++){ 
        ptr[i] = yytext[i+2];
    } 
    // imprime un mensaje con el número hexadecimal a convertir y llama a la función strtol para convertirlo en decimal
    fprintf(outFile,"Convirtiendo %s en base hexa a base decimal -> %d\n",yytext,(int)strtol(ptr, NULL, 16)); 
    // retorna el resultado de la conversión a decimal
    return (int)strtol(ptr, NULL, 16); 
}


void 	printSymbolTable(){
        fprintf(tableFile,"*** Tabla de Simbolos ***\n-------------------------\n");
        for(int i = 0; i < pointerTS; i++){
                fprintf(tableFile,"%6d | %s\t| %6d\n",i, symbolTable[i].name, symbolTable[i].type);
        }
        printf("\n");
}

void printStringTable(){
        fprintf(tableFile,"*** Tabla de Cadenas ***\n-------------------------\n");
        for(int i = 0; i < pointerTLString; i++){
                fprintf(tableFile,"%6d | %s\n",i, stringTable[i]);
        }
        printf("\n");
}
void printCharTable(){
        fprintf(tableFile,"*** Tabla de Caracteres ***\n-------------------------\n");
        for(int i = 0; i < pointerTLChar; i++){
                fprintf(tableFile,"%6d | %s\n",i, charTable[i]);
        }
        printf("\n");
}

void printRealTable(){
        fprintf(tableFile,"*** Tabla de Reales ***\n-------------------------\n");
        for(int i = 0; i < pointerTR; i++){
                fprintf(tableFile,"%6d | %.2f\n",i, realTable[i]);
        }
        printf("\n");
}

int main(int argc, char** argv) {
    
	// Abre el archivo de entrada especificado por el primer argumento de línea de comando
	FILE* inFile = fopen(argv[1], "r");	
	// Comprueba si se proporcionó exactamente un argumento de línea de comando
	if (argc != 2) {
		printf("Uso: %s <archivo_entrada>\n", argv[0]);
		return 1;
	}
	// Abre el archivo de salida "salida.txt" en modo de escritura
	outFile = fopen("salida.txt","w");
	tokenFile = fopen("token.txt","w");
	tableFile = fopen("tablas.txt","w");
	// Comprueba si se pudo abrir el archivo de entrada
	if (inFile == NULL) {
		printf("No se puede abrir el archivo: %s\n", argv[1]);
		return 1;
	}
	// Configura el archivo de entrada para que sea el que se usará con el analizador léxico (Flex)
	yyin = inFile;
	// Asigna memoria para las tablas de símbolos, números reales y cadenas de caracteres
	symbolTable 	= (identificador *)malloc(100*sizeof(identificador));                      
	realTable   	= (float *) malloc(sizeTR*sizeof(float));                
	stringTable   	= (char **)malloc(sizeTLString*sizeof(char *));
	charTable	= (char **)malloc(sizeTLChar*sizeof(char *));
	// Ejecuta el analizador léxico (Flex) para analizar la entrada y construir las tablas de símbolos
	yylex();
	// Imprime la tabla de símbolos generada por el analizador léxico
	printSymbolTable();
	printStringTable();
	printCharTable();
	printRealTable();
	
	// Libera la memoria asignada para las tablas de símbolos, números reales y cadenas de caracteres
	free(symbolTable);
	free(realTable);
	free(stringTable);
	free(charTable);
	// Cierra los archivos de entrada y salida
	fclose(inFile);
	fclose(outFile);
	fclose(tokenFile);
	fclose(tableFile);

    return 0;   
}
