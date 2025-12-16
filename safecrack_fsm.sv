module safecrack_fsm (
    input logic clk, // Clock 
    input logic rst_n, // Reset
    input logic [2:0] btn, // Botões
    output logic [7:0] led_green, // LEDs Verdes 
    output logic led_red // LED Vermelho 
);

    TODOS OS ESTADOS POSSÍVEIS
    typedef enum logic [2:0] {
        S_WAIT1, // Aguardando 1º Dígito (1 Verde)
        S_WAIT2, // Aguardando 2º Dígito (2 Verdes)
        S_WAIT3, // Aguardando 3º Dígito (3 Verdes)
        S_OPEN, // Sucesso (Todos Verdes por 5s)
        S_ERROR // Erro (1 Vermelho por 3s)
    } state_t;

    state_t state, next_state;

    localparam int TIME_3S = 150_000_000; 
    localparam int TIME_5S = 250_000_000;
    
    // LÓGICA DE TEMPO
    logic [$clog2(TIME_5S)-1:0] counter; 
    logic clear_timer; // Sinal para zerar o contador ao mudar de estado

    // LÓGICA DOS BOTÕES
    logic [2:0] btn_prev, btn_edge, btn_sync;
    logic any_btn_edge;

    always_comb begin
        btn_sync = ~btn; 
        btn_edge = btn_sync & ~btn_prev; 
        any_btn_edge = (|btn_edge); 
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_WAIT1;
            btn_prev <= 3'b000;
            counter <= 0;
        end else begin
            state <= next_state;
            btn_prev <= btn_sync;

            if (clear_timer) 
                counter <= 0;
            else if (state == S_ERROR || state == S_OPEN) 
                counter <= counter + 1;
            else 
                counter <= 0;
        end
    end

    always_comb begin
        next_state = state;
        clear_timer = 0;

        led_green = 8'b00000000;
        led_red = 1'b0;

        case (state)
            // ESTADO PADRÃO
            S_WAIT1: begin
                led_green = 8'b00000001; // 1 LED Verde
                
                if (btn_edge == 3'b001) begin // Botão 1 (Correto)
                    next_state = S_WAIT2;
                    clear_timer = 1;
                end else if (any_btn_edge) begin // Botão Errado
                    next_state = S_ERROR;
                    clear_timer = 1;
                end
            end

            // Espera Botão 2
            S_WAIT2: begin
                led_green = 8'b00000011; // 2 LEDs Verdes
                
                if (btn_edge == 3'b010) begin // Botão 2 (Correto)
                    next_state = S_WAIT3;
                    clear_timer = 1;
                end else if (any_btn_edge) begin // Botão Errado
                    next_state = S_ERROR;
                    clear_timer = 1;
                end
            end

            // Espera Botão 3
            S_WAIT3: begin
                led_green = 8'b00000111; // 3 LEDs Verdes
                
                if (btn_edge == 3'b100) begin // Botão 3 (Correto)
                    next_state = S_OPEN; // Vai para Sucesso
                    clear_timer = 1; // Prepara contador do timer
                end else if (any_btn_edge) begin // Botão Errado
                    next_state = S_ERROR;
                    clear_timer = 1;
                end
            end

            // SUCESSO: Aberto por 5s
            S_OPEN: begin
                led_green = 8'b11111111; // Todos LEDs Verdes
                
                if (counter >= TIME_5S) begin
                    next_state = S_WAIT1; 
                    clear_timer = 1;
                end
            end

            // ERRO: Bloqueado por 3s
            S_ERROR: begin
                led_red = 1'b1; // 1 LED Vermelho
                
                if (counter >= TIME_3S) begin
                    next_state = S_WAIT1;
                    clear_timer = 1;
                end
            end
            // VOLTA PRO ESTADO PADRÃO
            default: next_state = S_WAIT1;
        endcase
    end


endmodule
