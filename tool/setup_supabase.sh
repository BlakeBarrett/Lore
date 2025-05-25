#!/usr/bin/env bash

# Supabase Configuration Helper for Lore
# This script helps you set up or update your Supabase configuration

echo "🔧 Lore Supabase Configuration Helper"
echo "====================================="
echo ""

# Check if supabase.env exists
if [ -f "supabase.env" ]; then
    echo "📁 Found existing supabase.env file:"
    cat supabase.env
    echo ""
    
    # Extract current URL
    CURRENT_URL=$(grep "SUPABASE_URL=" supabase.env | cut -d'=' -f2 | tr -d "'\"")
    echo "🌐 Testing current URL: $CURRENT_URL"
    
    # Test connectivity
    if curl -s -I "$CURRENT_URL/rest/v1/" --max-time 10 > /dev/null 2>&1; then
        echo "✅ Current Supabase URL is accessible!"
        echo ""
        echo "Your configuration appears to be working. If you're still having issues,"
        echo "the problem might be with API keys or database setup."
        exit 0
    else
        echo "❌ Current Supabase URL is not accessible"
        echo ""
    fi
else
    echo "📁 No supabase.env file found"
    echo ""
fi

echo "🔧 To fix this, you need to:"
echo ""
echo "1. 🌐 Go to https://supabase.com/dashboard"
echo "2. 📝 Either:"
echo "   - Create a new project, or"
echo "   - Find your existing project"
echo "3. 📋 Copy the project settings:"
echo "   - Go to Settings > API"
echo "   - Copy the 'Project URL'"
echo "   - Copy the 'anon public' key"
echo ""
echo "4. 📝 Update your supabase.env file with:"
echo "   SUPABASE_URL='https://your-project-ref.supabase.co'"
echo "   SUPABASE_ANON_KEY='your-anon-key-here'"
echo ""
echo "5. 🧪 Run this script again to test the new configuration"
echo ""

# If they want to create a new config interactively
read -p "Would you like to enter new Supabase credentials now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 Enter your new Supabase configuration:"
    echo ""
    read -p "Project URL (e.g., https://xxxxx.supabase.co): " NEW_URL
    read -p "Anon Key: " NEW_KEY
    
    if [ -n "$NEW_URL" ] && [ -n "$NEW_KEY" ]; then
        echo "SUPABASE_URL='$NEW_URL'" > supabase.env
        echo "SUPABASE_ANON_KEY='$NEW_KEY'" >> supabase.env
        
        echo ""
        echo "✅ Created new supabase.env file"
        echo ""
        echo "🧪 Testing new configuration..."
        
        if curl -s -I "$NEW_URL/rest/v1/" --max-time 10 > /dev/null 2>&1; then
            echo "✅ New Supabase URL is accessible!"
            echo ""
            echo "🎉 Configuration updated successfully!"
            echo "You can now build and run the Lore console app."
        else
            echo "❌ New URL is not accessible. Please check:"
            echo "   - The URL is correct (should end with .supabase.co)"
            echo "   - The project exists and is not paused"
            echo "   - Your internet connection"
        fi
    else
        echo "❌ Invalid input. Please run the script again with valid credentials."
    fi
fi

echo ""
echo "📚 For more information, see:"
echo "   - Supabase Documentation: https://supabase.com/docs"
echo "   - Lore Console README: ./CONSOLE_README.md"
