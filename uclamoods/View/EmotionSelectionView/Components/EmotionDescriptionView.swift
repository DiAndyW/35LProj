import SwiftUI

struct EmotionDescriptionView: View {
    let emotion: Emotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with "I'm feeling" and emotion name
            VStack(alignment: .leading, spacing: 4) {
                Text("I'm feeling")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.custom("Georgia", size: 32))
                    .padding(.bottom, 0)
                
                
                Text(emotion.name)
                    .font(.custom("Georgia", size: 48))
                    .fontWeight(.bold)
                    .foregroundColor(emotion.color)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Divider for visual separation
            Rectangle()
                .frame(height: 1)
                .foregroundColor(emotion.color.opacity(0.3))
                .padding(.vertical, 2)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(white: 0.15))
                    .frame(height: 90)
                
                VStack(alignment: .leading) {
                    Text(emotion.description)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmotionDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            EmotionDescriptionView(emotion: EmotionDataProvider.highEnergyEmotions[3])
                .frame(height: 160)
                .padding()
        }
        .preferredColorScheme(.dark)
    }
}
