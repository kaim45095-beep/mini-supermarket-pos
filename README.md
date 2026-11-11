# Mini Supermarket POS

Mini Supermarket POS is a terminal-based checkout simulator written in **32-bit x86 assembly** for Linux. It models three ways to shop, with a shared cart and separate checkout steps for each mode.

## Shopping modes

| Mode | Workflow |
| --- | --- |
| Kiosk | Self-service checkout for guests or members, with an admin PIN to exit kiosk mode. |
| Staff counter | A staff PIN opens the checkout for in-store guests or members. |
| App order | A member signs in with demo credentials and selects home delivery or pickup at one of five stores. |

The simulator calculates totals in Malaysian ringgit, validates menu selections and quantities, and supports cart cancellation. Members can earn and redeem loyalty points during the session. In-store cash payments calculate change, and the card and QR options simulate approvals. The program uses sample credentials and keeps member balances in memory until it exits.

## Build and run

Use x86 Linux with support for 32-bit executables, NASM, and GNU Binutils. Open a terminal in the folder containing `minisupermarket.asm` and run the commands below.

```sh
nasm -f elf32 minisupermarket.asm -o minisupermarket.o
ld -m elf_i386 minisupermarket.o -o minisupermarket
./minisupermarket
```

## Try a sample checkout

Enter each number at its prompt and press **Enter**.

1. Select `1` for **Kiosk Mode**, then enter `0` to shop as a guest.
2. Select `1` for **Fruits** and enter a quantity of `2`.
3. Select `8` for **Checkout**. The total is **RM20**.
4. Select `1` for **Cash** and enter `50`. The program calculates **RM30** in change.

## Implementation

The program starts at `_start` and uses Linux system calls for terminal input, output, and exit. Assembly subroutines parse numeric input, display totals, and update loyalty-point balances. Conditional jumps route the three shopping modes through the cart and checkout flows.
