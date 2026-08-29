```text
                        ASYNCHRONOUS FIFO - BLOCK DIAGRAM
                        ==================================

       WRITE CLOCK DOMAIN (clk_w)                READ CLOCK DOMAIN (clk_r)
  +--------------------------------+       +---------------------------------+
  |                                |       |                                 |
  |  rst --+                       |       |                       +-- rst   |
  |        v                       |       |                       v         |
  |  +-------------------+         |       |         +-------------------+   |
  |  | reset_synchronizer|         |       |         | reset_synchronizer|   |
  |  |    (uut_rst_wr)   |         |       |         |    (uut_rst_rd)   |   |
  |  +----------+----------+       |       |         +----------+--------+   |
  |             | rst_w            |       |            rst_r  |             |
  |             v                  |       |                   v             |
  | data_in-->+-----------------+  |       |   +-----------------+<--rd_en   |
  | wr_en  -->|                 |  |       |   |                 |           |
  |           |  Write Control  |  |       |   |  Read Control   |           |
  |           |  & Pointer Logic|  |       |   |  & Pointer Logic|           |
  |           |                 |  |       |   |                 |           |
  |           |  wr_ptr_bn      |  |       |   |  rd_ptr_bn      |           |
  |           |  wr_ptr_gray    |  |       |   |  rd_ptr_gray    |           |
  |           +--------+--------+  |       |   +--------+--------+           |
  |                    |           |       |            |                    |
  |                    v           |       |            v                    |
  |          write = wr_en&&!full  |       |    read = rd_en&&!empty         |
  |                    |           |       |            |                    |
  |                    v           |       |            v                    |
  |         +-------------------+  |       |  +-------------------+          |
  |         |  Dual-Port Memory |<-+-------+->|  (shared array)   |----------+-> data_out
  |         |  memory[0:DEPTH-1]|  |       |  +-------------------+          |
  |         +-------------------+  |       |                                 |
  |                                |       |                                 |
  | +----------------------------+ |       |  +----------------------------+ |
  | |         full_next          | |       |  |        empty_next          | |
  | | (compares wr_ptr_gray_next | |       |  | (compares rd_ptr_gray_next | |
  | |   vs rd_ptr_sync)          | |       |  |   vs wr_ptr_sync)          | |
  | +-------------+--------------+ |       |  +-------------+--------------+ |
  |               v                |       |                v                |
  |          full (reg)            |       |           empty (reg)           |
  |                                |       |                                 |
  |     wr_ptr_gray                |       |               rd_ptr_gray       |
  |          |                     |       |                    |            |
  +----------+---------------------+       +--------------------+------------+
             |                                                  |
             |        ======= CLOCK DOMAIN CROSSING =======     |
             |                                                  |
             v                                                  v
  +--------------------------+                    +---------------------------+
  |  two_flop_synchronizer   |                    |  two_flop_synchronizer    |
  |      (uut_rd_sync)       |                    |      (uut_wr_sync)        |
  |                          |                    |                           |
  |  clk_B = clk_w           |                    |  clk_B = clk_r            |
  |  rst   = rst_w           |                    |  rst   = rst_r            |
  |                          |                    |                           |
  | rd_ptr_gray-->[FF]-->[FF]+--> rd_ptr_sync     | wr_ptr_gray-->[FF]-->[FF]-+-> wr_ptr_sync
  |                          |                    |                           |
  | (into clk_w domain,      |                    | (into clk_r domain,       |
  |  used by full_next)      |                    |  used by empty_next)      |
  +--------------------------+                   +----------------------------+
 
  Legend:
  [FF]  = flip-flop stage (metastability settling)
  rst_w / rst_r = synchronized, domain-local resets
  Gray-coded pointers ensure only 1 bit changes per transition,
  making the CDC crossing metastability-safe.
```