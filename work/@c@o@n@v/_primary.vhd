library verilog;
use verilog.vl_types.all;
entity CONV is
    generic(
        idle            : integer := 0;
        read            : integer := 1;
        work            : integer := 2;
        out_0           : integer := 3;
        out_0_temp      : integer := 4;
        pooling         : integer := 5;
        out_1           : integer := 6;
        out_1_temp      : integer := 7;
        finish          : integer := 8
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        busy            : out    vl_logic;
        ready           : in     vl_logic;
        iaddr           : out    vl_logic_vector(11 downto 0);
        idata           : in     vl_logic_vector(19 downto 0);
        cwr             : out    vl_logic;
        caddr_wr        : out    vl_logic_vector(11 downto 0);
        cdata_wr        : out    vl_logic_vector(19 downto 0);
        crd             : out    vl_logic;
        caddr_rd        : out    vl_logic_vector(11 downto 0);
        cdata_rd        : in     vl_logic_vector(19 downto 0);
        csel            : out    vl_logic_vector(2 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of idle : constant is 1;
    attribute mti_svvh_generic_type of read : constant is 1;
    attribute mti_svvh_generic_type of work : constant is 1;
    attribute mti_svvh_generic_type of out_0 : constant is 1;
    attribute mti_svvh_generic_type of out_0_temp : constant is 1;
    attribute mti_svvh_generic_type of pooling : constant is 1;
    attribute mti_svvh_generic_type of out_1 : constant is 1;
    attribute mti_svvh_generic_type of out_1_temp : constant is 1;
    attribute mti_svvh_generic_type of finish : constant is 1;
end CONV;
