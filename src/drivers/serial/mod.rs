pub struct Serial;

impl Serial {
    pub fn init() {
        unsafe {
            let resets_clr = (0x4002_0000 + 0x3000) as *mut u32;
            resets_clr.write_volatile((1 << 22) | (1 << 5));

            let resets_done = (0x4002_0000 + 0x8) as *const u32;
            while (resets_done.read_volatile() & ((1 << 22) | (1 << 5))) == 0 {}

            let gp0_ctrl = (0x4002_8000 + 0x04) as *mut u32;
            let gp1_ctrl = (0x4002_8000 + 0x0C) as *mut u32;
            gp0_ctrl.write_volatile(2);
            gp1_ctrl.write_volatile(2);

            let uart0 = 0x4003_4000;
            let uart_ibrd = (uart0 + 0x24) as *mut u32;
            let uart_fbrd = (uart0 + 0x28) as *mut u32;
            let uart_lcr_h = (uart0 + 0x2C) as *mut u32;
            let uart_cr = (uart0 + 0x30) as *mut u32;

            uart_cr.write_volatile(0);

            uart_ibrd.write_volatile(6);
            uart_fbrd.write_volatile(33);

            uart_lcr_h.write_volatile(0x70);

            uart_cr.write_volatile(0x301);
        }
    }

    #[inline(always)]
    pub fn write_byte(b: u8) {
        let uart_dr = 0x4003_4000 as *mut u32;
        let uart_fr = (0x4003_4000 + 0x18) as *const u32;

        unsafe {
            while (uart_fr.read_volatile() & (1 << 5)) != 0 {}
            
            uart_dr.write_volatile(b as u32);
        }
    }
}