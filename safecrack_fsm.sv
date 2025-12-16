module safecrack_pro (
    input  logic        clk,        // Clock 50 MHz
    input  logic        rst_n,      // Reset ativo em nível baixo
    input  logic [2:0]  btn,        // Botões (ativos em 0)
    output logic [7:0]  led_green,  // LEDs verdes
    output logic        led_red     // LED vermelho
);

    // -------------------------------------------------
    // DEFINIÇÃO DOS ESTADOS
    // -------------------------------------------------
    typedef enum logic [2:0] {
        S_WAIT1,
        S_WAIT2,
        S_WAIT3,
        S_OPEN,
        S_ERROR
    } state_t;

    state_t state, next_state;

    // -------------------------------------------------
    // CONSTANTES DE TEMPO (50 MHz)
    // -------------------------------------------------
    localparam int TIME_3S = 150_000_000;
    localparam int TIME_5S = 250_000_000;

    // Contador para temporização
    logic [$clog2(TIME_5S)-1:0] counter;

    // -------------------------------------------------
    // TRATAMENTO DOS BOTÕES (SINCRONIZAÇÃO + BORDA)
    // -------------------------------------------------
    logic [2:0] btn_sync;
    logic [2:0] btn_prev;
    logic [2:0] btn_edge;

    assign btn_sync = ~btn;            // Ativo em nível alto
    assign btn_edge = btn_sync & ~btn_prev;
    assign any_btn_edge = |btn_edge;

    logic any_btn_edge;

    // -------------------------------------------------
    // LÓGICA SEQUENCIAL (MEMÓRIA)
    // -------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_WAIT1;
            btn_prev  <= 3'b000;
            counter   <= '0;
        end else begin
            state    <= next_state;
            btn_prev <= btn_sync;

            // Temporizador
            if (state != next_state)
                counter <= '0;
            else if (state == S_OPEN || state == S_ERROR)
                counter <= counter + 1;
            else
                counter <= '0;
        end
    end

    // -------------------------------------------------
    // LÓGICA COMBINACIONAL (FSM + SAÍDAS)
    // -------------------------------------------------
    always_comb begin
        // Valores padrão
        next_state = state;
        led_green  = 8'b00000000;
        led_red    = 1'b0;

        case (state)

            // -------------------------
            // ESPERA DÍGITO 1
            // -------------------------
            S_WAIT1: begin
                led_green = 8'b00000001;

                if (btn_edge == 3'b001)
                    next_state = S_WAIT2;
                else if (any_btn_edge)
                    next_state = S_ERROR;
            end

            // -------------------------
            // ESPERA DÍGITO 2
            // -------------------------
            S_WAIT2: begin
                led_green = 8'b00000011;

                if (btn_edge == 3'b010)
                    next_state = S_WAIT3;
                else if (any_btn_edge)
                    next_state = S_ERROR;
            end

            // -------------------------
            // ESPERA DÍGITO 3
            // -------------------------
            S_WAIT3: begin
                led_green = 8'b00000111;

                if (btn_edge == 3'b100)
                    next_state = S_OPEN;
                else if (any_btn_edge)
                    next_state = S_ERROR;
            end

            // -------------------------
            // SUCESSO (5s)
            // -------------------------
            S_OPEN: begin
                led_green = 8'b11111111;

                if (counter == TIME_5S - 1)
                    next_state = S_WAIT1;
            end

            // -------------------------
            // ERRO (3s)
            // -------------------------
            S_ERROR: begin
                led_red = 1'b1;

                if (counter == TIME_3S - 1)
                    next_state = S_WAIT1;
            end

            default: next_state = S_WAIT1;
        endcase
    end

endmodule