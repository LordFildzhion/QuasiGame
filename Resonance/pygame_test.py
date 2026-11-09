import sys

print(sys.path)

import pygame
from resonance_foreign_driver import Driver

def messageCallback(msg, timestamp):
    print(msg, timestamp)
    sys.stdout.flush()

driver = Driver("PyGame")
driver.inputMessageStream("in_message", messageCallback)
driver.inputDataStream("in_data", messageCallback)

pygame.init()



# Set up the drawing window
screen = pygame.display.set_mode([500, 500])


#print('load')
#driver.pollEvents()
#pygame.display.flip()
#driver.pollEvents()
#driver.loadConfig('pygame.json')

# Run until the user asks to quit
running = True
while running:
    driver.pollEvents()

    # Did the user click the window close button?
    for event in pygame.event.get():
        if event.type == pygame.MOUSEBUTTONUP:
            driver.loadConfig('pygame.json')
        if event.type == pygame.QUIT:
            running = False

    # Fill the background with white
    screen.fill((255, 255, 255))

    # Draw a solid blue circle in the center
    pygame.draw.circle(screen, (0, 0, 255), (250, 250), 75)

    # Flip the display
    pygame.display.flip()

# Done! Time to quit.
pygame.quit()
