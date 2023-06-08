import multiprocessing as mp
from time import sleep, time
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords

def process_data(data, ns):
    # Perform some time-consuming processing on the data
    kiwi = ns.main
    print("hi")
    processed_data = ' '.join([t.form for t in kiwi.tokenize(data)])
    return processed_data

def worker(conn, data, ns):
    # Process a chunk of data and send it through the pipe
    kiwi = ns.main
    processed_data = process_data(data, kiwi)
    conn.send(processed_data)
    conn.close()

if __name__ == '__main__':
    data = ["건설장의 여러곳을 돌아보시며 거리의 전경이 정말 볼만하다고",
            "못내 만족해하신 경애하는 총비서동지께서는 주체성과 민족성.",
            "현대성을 살려 고상하고 품위있게 건설하면서도",
            "인민대중제일주의를 구현하여야 한다고 말씀하시였다.",
            "그러시고는 인민들의 편의를 우선시하는것은 도시건설에서",
            "핵이라고 할수 있다고 하시면서 주체건축에서는 해당 지역에 사는 인민들의 편의보장이 기본이라고 강조하시였다.",
            "경애하는 총비서동지의 가르치심을 받아안으며",
            "일군들은 우리의 건축물들이 과연 어떤것으로 되여야 하는가를 다시금 절감하였다.",
            "정녕 사색과 실천의 첫자리에 언제나 인민을 놓으시는 경애하는 총비서동지의 뜨거운 사랑의 손길에 의해 송화거리만이 아닌 이 땅의 모든 창조물들이 인민들의 편의와 리익을 최우선."]

    num_chunks = 4
    chunk_size = len(data) // num_chunks
    chunk1 = data[:chunk_size]
    chunk2 = data[chunk_size:2*chunk_size]
    chunk3 = data[2*chunk_size:3*chunk_size]
    chunk4 = data[3*chunk_size:]

    manager = mp.Manager()
    #manager.start() 
    k = Kiwi()
    idk = manager.Value(k)

    # Create two processes to split the work and calculate the sum
    process1 = mp.Process(target=worker, args=(chunk1, idk))
    process2 = mp.Process(target=worker, args=(chunk2, idk))
    process3 = mp.Process(target=worker, args=(chunk3, idk))
    process4 = mp.Process(target=worker, args=(chunk4, idk))

    # Start the processes
    start_time = time()
    process1.start()
    process2.start()
    process3.start()
    process4.start()

    # Receive the results from the processes
    result1 = parent_conn1.recv()
    result2 = parent_conn2.recv()
    result3 = parent_conn3.recv()
    result4 = parent_conn4.recv()

    # Wait for the processes to finish
    process1.join()
    process2.join()
    process3.join()
    process4.join()
    #manager.close()
    # Calculate the total sum
    processed_data = result1 + result2 + result3 + result4


    end_time = time()
    # Print the result and computation time
    print("List:", processed_data[1:10], "...")
    print("Computation Time:", end_time - start_time, "seconds")
