
Programação Concorrente 2022
Projeto 2

Introdução
Foi-nos pedido que realizássemos pequenas classes concorrentes em Java para implementações de conjuntos baseadas em tabelas de dispersão (“hash sets”).
O projeto foi desenvolvido num grupo de dois elementos e o principal objetivo era explorar variadas formas de implementar “hash sets” usando a concorrência, mais especificamente utilizando ReentrantLocks, ReentrantReadWriteLocks e Software Transactional Memory (STM). Para isso, foi-nos fornecido o código base que incluía código para ajuda a compilação assim como exemplos de teste.
Para além disso tivemos acesso a um ficheiro HSet0.java que servia como exemplo (e base) de como implementar esta estrutura de dados usando sincronização de threads.

Hash Sets
Procedemos com a descrição da implementação de “hash sets” que nos foi dada no enunciado do projeto por razões de tempo e de clareza:
“Consideramos implementações concorrentes de conjuntos que usam uma representação interna na forma de uma tabela de “hashing” com o típico esquema de “hashing” aberto, ilustrada na imagem abaixo, em que:
os elementos do conjunto são dispersos por entradas em uma tabela de “hashing” (um array de entradas) em que cada posição referência uma lista ligada de elementos implementada por objectos de tipo LinkedList (note que LinkedList não tem qualquer mecanismo de sincronização entre threads;
a entrada (lista) na tabela associada a um elemento x no conjunto é dada por table[Math.abs(x.hashCode()) % table.length];

A interface IHSet em src/IHSet.java exprime um tipo abstracto de dados para os conjunto com as seguintes operações:
size(): devolve o tamanho do conjunto;
add(e): adiciona o elemento e ao conjunto;
remove(e): remove o elemento e do conjunto;
contains(e): testa se o elemento e pertence ao conjunto;
waitFor(e): retorna imediatamente se e pertencer ao conjunto, caso contrário espera que o elemento e seja adicionado ao conjunto, bloqueando a thread em contexto;
rehash(): redimensiona a tabela de hashing.

HSet1.java:
O objetivo deste primeiro “exercício” foi trocar o uso da sincronização por ReentrantLock, para tal, tivemos de criar um lock ReentrantLock rl e uma condição Condition contElem (ligada ao rl) “globais” para além de fazer as seguintes alterações nas operações:
size(): inicialmente a thread adquire o lock (rl.lock()) e só faz unlock (rl.unlock()) depois de retornar o valor size (inteiro que indica o tamanho da conjunto);
add(e): inicialmente verificamos se o elemento a adicionar é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão a thread adquire o lock (rl.lock()), adicionamos o elemento ao conjunto (se ele ainda não o tiver), usamos a condição contElem em signalAll() para acordar todas as threads que estejam à espera em waitFor(e), aumentamos o size, retornamos se o elemento foi adicionado ou não, e finalmente unlock (rl.unlock());
remove(e): análogo ao anterior com a diferença de retirarmos o elemento em vez de o adicionar, de não precisarmos da condição e de diminuirmos o size em vez de o aumentar;
contains(e): inicialmente a thread adquire o lock (rl.lock()), retorna se e pertence ao conjunto e faz unlock (rl.unlock());
waitFor(e): inicialmente verificamos se o elemento é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão a thread adquire o lock (rl.lock()). Retorna imediatamente se ele pertencer ao conjunto e faz unlock (rl.unlock()), caso contrário fica à espera do sinal que ele foi adicionado ou que foi interrompido com contElem.await() e quando isto se verificar ele liberta o lock;
rehash():  inicialmente a thread adquire o lock (rl.lock()), redimensiona a tabela de hashing, ajusta os seus elementos e faz unlock (rl.unlock());

HSet2.java:
Desta vez implementamos usando ReentrantReadWriteLocks (rrwl) que nos permite adicionar recursos de segurança e eficiência à estrutura de dados, permitindo que vários threads leiam os dados simultaneamente e um thread atualize (escreva) os dados exclusivamente.
Continuamos com a condição Condition contElem mas desta vez com a particularidade de estar apenas ligadas a locks de escrita (rrwl.writeLock().newCondition()) pois só precisamos da condição quando estamos a atualizar (“read locks” não suportam variáveis de condição de qualquer forma)

size(): inicialmente a thread adquire o lock de leitura (rrwl.readLock().lock()) e só faz unlock (rrwl.readLock().unlock()) depois de retornar o valor size;
add(e): inicialmente verificamos se o elemento a adicionar é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão a thread adquire o lock de escrita (rrwl.writeLock().lock()), adicionamos o elemento ao conjunto (se ele ainda não o tiver), usamos a condição contElem em signalAll() para acordar todas as threads que estejam à espera em waitFor(e), aumentamos o size, retornamos se o elemento foi adicionado ou não, e finalmente unlock (rrwl.writeLock().unlock());
remove(e): análogo ao anterior, com lock de escrita, com a diferença de retirarmos o elemento em vez de o adicionar, de não precisarmos da condição e de diminuirmos o size em vez de o aumentar;
contains(e): inicialmente a thread adquire o lock de leitura (rrwl.readLock().lock()), retorna se e pertence ao conjunto e faz unlock (rrwl.readLock().unlock());
waitFor(e): inicialmente verificamos se o elemento é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão a thread adquire o lock de escrita (rrwl.writeLock().lock()) embora este método não modifique o conjunto, precisa deste lock para o uso da condição. Retorna imediatamente se o elemento pertencer ao conjunto e faz unlock (rrwl.writeLock().unlock()), caso contrário fica à espera do sinal que ele foi adicionado ou que foi interrompido com contElem.await() e quando isto se verificar ele liberta o lock;
rehash():  inicialmente a thread adquire o lock de escrita (rrwl.writeLock().lock()), redimensiona a tabela de hashing, ajusta os seus elementos e faz unlock (rrwl.writeLock().unlock());

HSet3.java:
Com objetivo de termos concorrência acrescida nas várias operações, em vez de termos um lock e condição globais, cada entrada do conjunto da tabela de hashing terá os seus próprios. Uma thread só bloqueia se houver outra thread a aceder à mesma entrada da tabela ou a uma entrada da tabela governada pelo mesmo lock.
HSet3(ht_size): ao contrário das classes que implementamos anteriormente, tivemos de fazer alterações no construtor devido ao que referimos no início deste tópico. Criamos um array de locks (locks = new ReentrantReadWriteLock[ht_size]) com o tamanho inicial da “hash table” e o mesmo com as condições (conds = new Condition[ht_size]). De seguida inicializamos cada índice do array de locks e do array de condições através de um ciclo.
size(): o campo global size (inteiro que indicava, anteriormente, o tamanho da conjunto) foi suprimido. Em sua vez este valor será calculado e retornado “aqui dentro”. Inicialmente a thread adquire os locks de leitura (locks[i].readLock().lock()) de todas as entradas da tabela através de um ciclo que a percorre. De seguida o acumulador size é inicializado a zero e vai incrementando à medida que corre os elementos do conjunto. Por fim, retorna esse valor e faz unlock (locks[i].readLock().unlock()) de todos os locks adquiridos pela thread através de um novo ciclo;


add(e): inicialmente verificamos se o elemento a adicionar é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão criamos um lock de escrita (lock) e uma condição (contElem) para a posição desse elemento (locks[Math.abs(elem.hashCode() % locks.length)] e conds[Math.abs(elem.hashCode() % locks.length)]) e a thread adquire o lock (lock.writeLock().lock()). Depois adicionamos o elemento ao conjunto (se ele ainda não o tiver), usamos a condição em signalAll() para acordar todas as threads que estejam à espera em waitFor(e), retornamos se o elemento foi adicionado ou não, e finalmente unlock (lock.writeLock().unlock());
remove(e): análogo ao anterior, com o lock de escrita da posição do elemento, com a diferença de retirarmos o elemento em vez de o adicionar e de não precisarmos da condição;
contains(e): inicialmente a thread adquire o lock de leitura na posição do elemento (ReentrantReadWriteLock lock = locks[Math.abs(elem.hashCode() % locks.length)]; lock.readLock().lock()), retorna se e pertence ao conjunto e faz unlock (lock.readLock().unlock());
waitFor(e): inicialmente verificamos se o elemento é nulo, se for o caso fazemos uma throw new IllegalArgumentException(), senão a thread adquire o lock de leitura na posição do elemento (ReentrantReadWriteLock lock = locks[Math.abs(elem.hashCode() % locks.length)]; lock.readLock().lock()) e da sua respectiva condição. Retorna imediatamente se o elemento pertencer ao conjunto e faz unlock (lock.writeLock().unlock()), caso contrário fica à espera do sinal que ele foi adicionado ou que foi interrompido com contElem.await() e quando isto se verificar ele liberta o lock;
rehash():  Inicialmente a thread adquire os locks de escrita (locks[i].writeLock().lock()) de todas as entradas da tabela através de um ciclo que a percorre. Depois redimensiona a tabela de hashing, ajusta os elementos e faz unlock (locks[i].writeLock().unlock()) de todos os locks adquiridos pela thread através de um novo ciclo;

HSet4.java:
Esta classe é ainda mais diferente de todas as outras porque nos foi dada a tarefa de implementar usando a biblioteca ScalaSTM. Em vez de utilizarmos uma LinkedList estamos agora a trabalhar sobre uma “lista” duplamente ligada e array de transições (TArray), então tivemos de fazer alterações que não estavam presentes nas classes anteriores;
elemIndex(e): como já não estamos a utilizar a biblioteca da LinkedList, precisamos de criar este método retorna o índice de um dado elemento e na tabela, utilizando a sua posição como fizemos anteriormente (Math.abs(elem.hashCode() % table.get().length()) com a adição dos métodos get() e length() da biblioteca do TArray do STM;
getEntry(e): implementamos este método pela mesma razão do anterior. Ele retorna o nó na posição (índice) do elemento e. Para isso, usamos o método apply() da mesma biblioteca referida anteriormente que executa uma leitura transacional do elemento nesse dado índice (elemIndex(elem));
add(e): É criado um novo nó e é-lhe atribuído o valor do argumento.  Se o nó inicial for nulo, o nó seguinte do novo nó é colocado como nulo. Se o nó inicial não for nulo, o nó seguinte do novo nó é colocado como o nó inicial e o nó anterior ao inicial como o novo nó. 
remove(e): Inicialmente verificamos se o tal nó que se pretende remover existe ou não na tabela. Se existir, prosseguimos a modificar os prev e next dos nós anterior e seguinte ao nó que se remove. Desta forma mantendo a lista duplamente ligada de forma correta, e o nó pretendido deixa de ser alcançável;
waitFor(e): inicialmente verificamos se o elemento é nulo, se for o caso fazemos uma throw new IllegalArgumentException(). Fica à espera do sinal que ele foi adicionado e quando isto se verificar ele invoca de novo o STM.atomic;
rehash(): redimensiona a tabela de hashing. De seguida vai ajustando os nós e as suas ligações à “nova” tabela com recurso novamente ao método apply();

Validação:
Todas as nossas classes passaram nos testes (scripts teste1.sh e teste2.sh) conforme o docente indicou, portanto assumimos que as nossas implementações estão corretas.


Problemas do trabalho:
Numa fase inicial, os nossos terminais em Ubuntu 20.04 WSL não estavam a dar permissão para compilar e realizar os testes. No entanto, com o uso de uma VM este problema foi resolvido.
O HSet4 causou algumas dificuldades de como a implementação do ScalaSTM seria feita pois é um “paradigma” ao qual não estávamos tão habituados.
Ficamos muito ligados aos testes de validação, pelo que se os nossos programas estiverem com algum erro que não foi detectado pelos testes nós não conseguimos notar e corrigir antes da entrega.

Conclusão:
Acreditamos que o objetivo deste projeto foi alcançado com satisfação pois conseguimos programar classes que têm a mesma funcionalidade mas que são implementadas de formas completamente diferentes. Sendo assim, aprendemos ainda mais sobre sincronização de threads, ReentrantLocks, ReentrantReadWriteLocks e sobre ScalaSTM durante a realização deste projeto.

Bibliografia:
Documentação da classe ReentrantLock
Documentação da interface Condition
Documentação da classe ReentrantReadWriteLock
Documentação de ScalaSTM
Documentação de TArray


