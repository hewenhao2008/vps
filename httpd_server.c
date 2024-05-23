#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 65000
// 获取客户端的外网IP地址
char* get_client_ip(int client_socket) {
    struct sockaddr_in addr;
    socklen_t addr_size = sizeof(struct sockaddr_in);
    getpeername(client_socket, (struct sockaddr*)&addr, &addr_size);
    return inet_ntoa(addr.sin_addr);
}

int main() {
    // 创建服务器套接字
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);

    // 绑定服务器地址
    struct sockaddr_in server_address;
    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(PORT);
    server_address.sin_addr.s_addr = INADDR_ANY;
    bind(server_socket, (struct sockaddr*)&server_address, sizeof(server_address));
    
 //Prevent ip multiplexing
    int one = 1;
    if (setsockopt(server_socket , SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one)) < 0) {
        close(server_socket);
        printf("setsockopt SO_REUSEADDR error \n");
        return -1;
    }

    // 监听
    listen(server_socket, 5);

    while (1) {
        // 接受客户端连接
        int client_socket = accept(server_socket, NULL, NULL);

        // 获取客户端IP地址
        char* client_ip = get_client_ip(client_socket);

        // 构建HTTP响应
        char response[1024];
        sprintf(response, "HTTP/1.1 200 OK\r\nContent-Length: %lu\r\n\r\n%s", strlen(client_ip), client_ip);

        // 发送HTTP响应
        send(client_socket, response, strlen(response), 0);

        // 关闭客户端套接字
        close(client_socket);
    }

    // 关闭服务器套接字
    close(server_socket);

    return 0;
}
